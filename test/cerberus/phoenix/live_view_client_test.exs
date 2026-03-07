defmodule Cerberus.Phoenix.LiveViewClientTest do
  use ExUnit.Case, async: true

  alias Cerberus.Phoenix.LiveViewClient
  alias Phoenix.LiveViewTest.View

  defmodule DummyLiveView do
    use GenServer, restart: :temporary

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts)
    end

    def init(opts) do
      {:ok, opts}
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

    def handle_call(:url, _from, state) do
      {:reply, {:ok, state.url}, state}
    end
  end

  test "receive_navigation consumes redirect messages from the proxy caller mailbox" do
    {_view_pid, _proxy_pid, view, ref, topic} = dummy_view()
    send(self(), {ref, {:redirect, topic, %{to: "/articles"}}})

    assert {:redirect, %{to: "/articles"}} = LiveViewClient.receive_navigation(view)
  end

  test "render_version changes when proxy state changes" do
    {_view_pid, proxy_pid, view, _ref, _topic} = dummy_view()
    before_version = LiveViewClient.render_version(view)
    DummyProxy.bump(proxy_pid, html_tree: [{"div", [], ["changed"]}])
    after_version = LiveViewClient.render_version(view)

    assert before_version != after_version
  end

  test "await_progress returns diff when the proxy state changes" do
    {_view_pid, proxy_pid, view, _ref, _topic} = dummy_view()
    version = LiveViewClient.render_version(view)

    spawn(fn ->
      Process.sleep(10)
      DummyProxy.bump(proxy_pid, html_tree: [{"div", [], ["changed"]}])
    end)

    assert {:ok, :diff} = LiveViewClient.await_progress(view, version, 500)
  end

  test "await_progress reports terminated when the live view dies" do
    {view_pid, _proxy_pid, view, _ref, _topic} = dummy_view()
    version = LiveViewClient.render_version(view)
    Process.exit(view_pid, :kill)

    assert {:ok, :terminated} = LiveViewClient.await_progress(view, version, 500)
  end

  defp dummy_view do
    {:ok, view_pid} = start_supervised(DummyLiveView)
    {:ok, proxy_pid} = start_supervised({DummyProxy, []}, id: make_ref())
    ref = make_ref()
    topic = "lv:test"

    view = %View{
      id: "test",
      pid: view_pid,
      proxy: {ref, topic, proxy_pid},
      module: Cerberus.Fixtures.CounterPageLive,
      endpoint: Cerberus.Fixtures.Endpoint
    }

    {view_pid, proxy_pid, view, ref, topic}
  end
end
