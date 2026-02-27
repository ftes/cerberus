defmodule Cerberus.LiveViewWatcherTest do
  use ExUnit.Case, async: true

  alias Cerberus.LiveViewWatcher

  defmodule DummyLiveView do
    use GenServer, restart: :temporary

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts)
    end

    def redirect(pid) do
      GenServer.call(pid, :redirect)
    end

    def init(opts) do
      {:ok, opts}
    end

    def handle_call(:redirect, _from, state) do
      reason = {:shutdown, {:redirect, %{to: "/articles"}}}
      {:stop, reason, state}
    end
  end

  test "watches the initial view when started" do
    {:ok, view_pid} = start_supervised(DummyLiveView)
    view = %{pid: view_pid}
    {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

    %{views: views} = :sys.get_state(watcher)
    watched_views = Map.keys(views)

    assert view_pid in watched_views
  end

  test "sends :live_view_died when watched live view dies" do
    {:ok, view_pid} = start_supervised(DummyLiveView)
    view = %{pid: view_pid}
    {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

    :ok = LiveViewWatcher.watch_view(watcher, view)
    Process.exit(view_pid, :kill)

    assert_receive {:watcher, ^view_pid, :live_view_died}
  end

  test "sends :live_view_redirected when watched live view redirects" do
    {:ok, view_pid} = start_supervised(DummyLiveView)
    view = %{pid: view_pid}
    {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

    :ok = LiveViewWatcher.watch_view(watcher, view)

    spawn(fn ->
      DummyLiveView.redirect(view_pid)
    end)

    assert_receive {:watcher, ^view_pid, {:live_view_redirected, {:redirect, %{to: "/articles"}}}}
  end

  test "preserves existing metadata when same view is watched again" do
    {:ok, view_pid} = start_supervised(DummyLiveView)
    view = %{pid: view_pid}
    {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

    %{views: before_views} = :sys.get_state(watcher)
    %{live_view_ref: original_ref} = before_views[view_pid]

    :ok = LiveViewWatcher.watch_view(watcher, view)

    %{views: after_views} = :sys.get_state(watcher)
    assert %{live_view_ref: ^original_ref} = after_views[view_pid]
  end

  test "can watch multiple live views concurrently" do
    {:ok, view_pid_1} = start_supervised({DummyLiveView, []}, id: {:dummy_live_view, 1})
    {:ok, view_pid_2} = start_supervised({DummyLiveView, []}, id: {:dummy_live_view, 2})
    view_1 = %{pid: view_pid_1}
    view_2 = %{pid: view_pid_2}

    {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view_1}})

    :ok = LiveViewWatcher.watch_view(watcher, view_1)
    :ok = LiveViewWatcher.watch_view(watcher, view_2)

    %{views: views} = :sys.get_state(watcher)
    watched_views = Map.keys(views)

    assert view_pid_1 in watched_views
    assert view_pid_2 in watched_views
  end
end
