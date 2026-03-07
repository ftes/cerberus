defmodule Cerberus.PhoenixLoopTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Phoenix.ConnTest, only: [build_conn: 0]

  alias Cerberus.Driver.Live
  alias Cerberus.Driver.Static
  alias Cerberus.Fixtures.Endpoint
  alias Cerberus.PhoenixLoop
  alias ExUnit.AssertionError
  alias Phoenix.LiveViewTest.View

  defmodule DummyLiveView do
    use GenServer, restart: :temporary

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts)
    end

    def render_html(pid) do
      GenServer.call(pid, :render_html)
    end

    def init(opts) do
      {:ok, opts}
    end

    def handle_call({:phoenix, :ping}, _from, state) do
      {:reply, :ok, state}
    end

    def handle_call(:render_html, _from, state) do
      {:reply, "rendered HTML", state}
    end
  end

  defmodule DummyProxy do
    @moduledoc false
    use GenServer, restart: :temporary

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts)
    end

    def bump(pid, opts \\ []) do
      GenServer.cast(pid, {:bump, opts})
    end

    def init(opts) do
      {:ok,
       %{
         html_tree: Keyword.get(opts, :html_tree, [{"div", [], ["initial"]}]),
         page_title: Keyword.get(opts, :page_title, :unset),
         url: Keyword.get(opts, :url, "http://www.example.com/live/counter"),
         views: %{}
       }}
    end

    def handle_cast({:bump, opts}, state) do
      {:noreply,
       %{
         state
         | html_tree: Keyword.get(opts, :html_tree, [{"div", [], ["updated"]}]),
           page_title: Keyword.get(opts, :page_title, state.page_title),
           url: Keyword.get(opts, :url, state.url)
       }}
    end

    def handle_call({:render_element, :find_element, {_topic, "render", nil}}, _from, state) do
      {:reply, {:ok, "rendered HTML"}, state}
    end

    def handle_call(:url, _from, state) do
      {:reply, {:ok, state.url}, state}
    end
  end

  test "retries when proxy progress changes rendered state" do
    {session, proxy_pid, _ref, _topic} = dummy_live_session()
    attempt_key = make_ref()

    action = fn live_session ->
      attempt = Process.get(attempt_key, 0) + 1
      Process.put(attempt_key, attempt)

      if attempt < 3 do
        DummyProxy.bump(proxy_pid, html_tree: [{"div", [], ["attempt #{attempt}"]}])
        raise AssertionError, message: "example failure"
      else
        DummyLiveView.render_html(live_session.view.pid)
      end
    end

    rendered = PhoenixLoop.run(session, 1_000, action)

    assert rendered == "rendered HTML"
    assert Process.get(attempt_key) == 3
  end

  test "short timeout does not wait the full legacy interval before retrying" do
    {session, _proxy_pid, _ref, _topic} = dummy_live_session()
    timeout = 20
    started_at = System.monotonic_time(:millisecond)

    assert_raise AssertionError, fn ->
      PhoenixLoop.run(session, timeout, fn _live_session ->
        raise AssertionError, message: "example failure"
      end)
    end

    elapsed = System.monotonic_time(:millisecond) - started_at
    assert elapsed <= timeout + 80
  end

  test "applies redirect notifications while retrying" do
    {session, _proxy_pid, ref, topic} = dummy_live_session("/live/redirects")

    send(self(), {ref, {:redirect, topic, %{to: "/main"}}})

    action = fn updated_session ->
      if current_path(updated_session, return_result: true) == "/main" do
        :redirected
      else
        raise AssertionError, message: "expected redirect to /main"
      end
    end

    assert :redirected = PhoenixLoop.run(session, 1_000, action)
  end

  test "handles redirect that switches from live to static session" do
    {session, _proxy_pid, ref, topic} = dummy_live_session("/live/redirects")
    attempt_key = make_ref()
    send(self(), {ref, {:redirect, topic, %{to: "/page/index"}}})

    action = fn
      %Live{current_path: "/live/redirects"} ->
        raise AssertionError, message: "waiting for redirect"

      %Static{} = redirected_session ->
        attempt = Process.get(attempt_key, 0) + 1
        Process.put(attempt_key, attempt)

        assert current_path(redirected_session, return_result: true) == "/page/index"

        if attempt < 2 do
          raise AssertionError, message: "retry once on redirected static page"
        else
          :redirected
        end
    end

    assert :redirected = PhoenixLoop.run(session, 1_000, action)
    assert Process.get(attempt_key) == 2
  end

  test "attempts redirect fallback when the live view dies before timeout" do
    {session, _proxy_pid, _ref, _topic} = dummy_live_session()
    view_pid = session.view.pid
    test_pid = self()

    action = fn
      %{view: %{pid: ^view_pid}} ->
        Process.exit(view_pid, :kill)
        DummyLiveView.render_html(view_pid)

      redirected_session ->
        assert current_path(redirected_session, return_result: true) == "/main"
        :ok
    end

    fetch_redirect_info = fn failed_session ->
      send(test_pid, {:redirect_attempted, from_view: failed_session.view.pid})
      {"/main", %{}}
    end

    assert :ok = PhoenixLoop.run(session, 1_000, action, fetch_redirect_info)
    assert_receive {:redirect_attempted, from_view: ^view_pid}
  end

  defp dummy_live_session(path \\ "/live/counter") do
    {:ok, view_pid} = start_supervised(DummyLiveView)

    {:ok, proxy_pid} =
      start_supervised({DummyProxy, url: "http://www.example.com#{path}"}, id: make_ref())

    ref = make_ref()
    topic = "lv:test"

    view = %View{
      id: "test",
      pid: view_pid,
      proxy: {ref, topic, proxy_pid},
      module: Cerberus.Fixtures.CounterPageLive,
      endpoint: Endpoint
    }

    {
      %Live{
        endpoint: Endpoint,
        conn: build_conn(),
        view: view,
        document: Cerberus.Html.parse!(""),
        form_data: %{active_form: nil, values: %{}},
        scope: nil,
        current_path: path,
        last_result: nil
      },
      proxy_pid,
      ref,
      topic
    }
  end
end
