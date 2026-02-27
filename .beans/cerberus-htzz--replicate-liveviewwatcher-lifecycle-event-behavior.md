---
# cerberus-htzz
title: Replicate LiveViewWatcher lifecycle event behavior
status: todo
type: task
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T11:31:31Z
parent: cerberus-zqpu
---

## Scope
Replicate watcher process behavior for LiveView lifecycle events and multi-view tracking, which underpins robust timeout + redirect handling.

## PhoenixTest Source Snippet
`/tmp/phoenix_test/test/phoenix_test/live_view_watcher_test.exs`

```elixir
test "sends :live_view_died message when LiveView dies" do
  {:ok, view_pid} = start_supervised(DummyLiveView)
  view = %{pid: view_pid}
  {:ok, watcher} = start_supervised({LiveViewWatcher, %{caller: self(), view: view}})

  :ok = LiveViewWatcher.watch_view(watcher, view)
  Process.exit(view_pid, :kill)

  assert_receive {:watcher, ^view_pid, :live_view_died}
end

test "sends :live_view_redirected message when LiveView redirects" do
  # ...
  assert_receive {:watcher, ^view_pid, {:live_view_redirected, _redirect_data}}
end

test "can watch multiple LiveViews" do
  # ...
  assert view_pid1 in watched_views
  assert view_pid2 in watched_views
end
```

## Done When
- [ ] Watcher emits deterministic messages for died/redirected views.
- [ ] Existing view metadata is preserved on repeated watch calls.
- [ ] Multiple concurrent watched views are supported and tested.
