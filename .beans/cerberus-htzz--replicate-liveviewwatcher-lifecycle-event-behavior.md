---
# cerberus-htzz
title: Replicate LiveViewWatcher lifecycle event behavior
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T19:16:53Z
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
- [x] Watcher emits deterministic messages for died/redirected views.
- [x] Existing view metadata is preserved on repeated watch calls.
- [x] Multiple concurrent watched views are supported and tested.

## Summary of Changes
- Added dedicated watcher lifecycle tests in `test/cerberus/live_view_watcher_test.exs` modeled after PhoenixTest coverage.
- Verified deterministic watcher messages for both live view death and redirect shutdown events.
- Verified repeated `watch_view/2` calls preserve existing internal metadata (`live_view_ref`) for already tracked views.
- Verified concurrent multi-view tracking in a single watcher process.

## Validation
- `mix test test/cerberus/live_view_watcher_test.exs test/cerberus/live_view_timeout_test.exs`
- `mix test test/core/live_navigation_test.exs test/core/live_link_navigation_test.exs`
- `mix precommit` (Credo passes; Dialyzer still reports existing baseline project warnings)
