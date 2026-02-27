defmodule Cerberus.LiveViewTimeoutTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Phoenix.ConnTest, only: [build_conn: 0]

  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Fixtures.Endpoint
  alias Cerberus.LiveViewTimeout
  alias ExUnit.AssertionError

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

  test "retries action at an interval when assertion fails" do
    session = dummy_live_session()
    attempt_key = make_ref()

    action = fn live_session ->
      attempt = Process.get(attempt_key, 0) + 1
      Process.put(attempt_key, attempt)

      if attempt < 3 do
        raise AssertionError, message: "example failure"
      else
        DummyLiveView.render_html(live_session.view.pid)
      end
    end

    rendered = LiveViewTimeout.with_timeout(session, 1_000, action)

    assert rendered == "rendered HTML"
    assert Process.get(attempt_key) == 3
  end

  test "applies watcher redirect notifications while retrying" do
    session = dummy_live_session("/live/redirects")
    view_pid = session.view.pid

    send(self(), {:watcher, view_pid, {:live_view_redirected, {:redirect, %{to: "/main"}}}})

    action = fn updated_session ->
      if current_path(updated_session) == "/main" do
        :redirected
      else
        raise AssertionError, message: "expected redirect to /main"
      end
    end

    assert :redirected = LiveViewTimeout.with_timeout(session, 1_000, action)
  end

  test "attempts redirect fallback when the live view dies before timeout" do
    session = dummy_live_session()
    view_pid = session.view.pid
    test_pid = self()

    action = fn
      %{view: %{pid: ^view_pid}} ->
        Process.exit(view_pid, :kill)
        DummyLiveView.render_html(view_pid)

      redirected_session ->
        assert current_path(redirected_session) == "/main"
        :ok
    end

    fetch_redirect_info = fn failed_session ->
      send(test_pid, {:redirect_attempted, from_view: failed_session.view.pid})
      {"/main", %{}}
    end

    assert :ok = LiveViewTimeout.with_timeout(session, 1_000, action, fetch_redirect_info)
    assert_receive {:redirect_attempted, from_view: ^view_pid}
  end

  test "attempts redirect fallback when timeout expires before watcher message" do
    session = dummy_live_session()
    view_pid = session.view.pid
    test_pid = self()
    timeout = LiveViewTimeout.interval_wait_time() - 10

    action = fn
      %{view: %{pid: ^view_pid}} ->
        Process.exit(view_pid, :kill)
        DummyLiveView.render_html(view_pid)

      redirected_session ->
        assert current_path(redirected_session) == "/main"
        :ok
    end

    fetch_redirect_info = fn failed_session ->
      send(test_pid, {:redirect_attempted, from_view: failed_session.view.pid})
      {"/main", %{}}
    end

    assert :ok = LiveViewTimeout.with_timeout(session, timeout, action, fetch_redirect_info)
    assert_receive {:redirect_attempted, from_view: ^view_pid}
  end

  defp dummy_live_session(path \\ "/live/counter") do
    {:ok, view_pid} = start_supervised(DummyLiveView)

    %LiveSession{
      endpoint: Endpoint,
      conn: build_conn(),
      view: %{pid: view_pid},
      html: "",
      form_data: %{active_form: nil, values: %{}},
      scope: nil,
      current_path: path,
      last_result: nil
    }
  end
end
