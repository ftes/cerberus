---
# cerberus-7ak7
title: Replicate LiveViewTimeout retry and redirect-resilience behavior
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T19:15:01Z
parent: cerberus-zqpu
---

## Scope
Replicate low-level `LiveViewTimeout.with_timeout/3` resilience behavior: retry loops, watcher-driven redirect handling, and redirect fallback when view dies.

## PhoenixTest Source Snippet
`/tmp/phoenix_test/test/phoenix_test/live_view_timeout_test.exs`

```elixir
test "retries action at an interval when it fails", %{session: session} do
  action = fn session ->
    case Enum.random([:fail, :fail, :pass]) do
      :fail -> raise ExUnit.AssertionError, message: "Example failure"
      :pass -> DummyLiveView.render_html(session.view.pid)
    end
  end

  assert "rendered HTML" = LiveViewTimeout.with_timeout(session, 1000, action)
end

test "redirects when LiveView notifies of redirection", %{session: session} do
  %{view: %{pid: view_pid}} = session

  action = fn
    %{view: %{pid: ^view_pid}} -> DummyLiveView.redirect(view_pid)
    _redirected_view -> :redirected
  end

  assert :redirected = LiveViewTimeout.with_timeout(session, 1000, action)
end

test "tries to redirect if the LiveView dies before timeout", %{session: session} do
  # ...
  :ok = LiveViewTimeout.with_timeout(session, 1000, action, fetch_redirect_info)
  assert_receive {:redirect_attempted, from_view: ^view_pid}
end
```

## Done When
- [x] Timeout loop retries failed assertions/actions until timeout.
- [x] Redirect notifications from watcher are applied during retries.
- [x] Dead-view fallback attempts redirect using provided redirect resolver.

## Summary of Changes
- Added `Cerberus.LiveViewTimeout` to provide retry-aware `with_timeout/4` logic for live sessions, including watcher-driven redirect handling and dead-view redirect fallback.
- Added `Cerberus.LiveViewWatcher` to monitor one or more live view PIDs and emit deterministic watcher messages (`:live_view_redirected`, `:live_view_died`).
- Added `Cerberus.Driver.Live.follow_redirect/2` as a small helper used by timeout handling to re-enter normal visit flow after redirects.
- Added focused tests in `test/cerberus/live_view_timeout_test.exs` covering retry loops, watcher-driven redirect application, and fallback redirect behavior when the live view dies.

## Validation
- `mix test test/cerberus/live_view_timeout_test.exs`
- `mix test test/cerberus/live_view_timeout_test.exs test/core/live_navigation_test.exs test/core/live_link_navigation_test.exs`
- `mix precommit` (Credo passes; Dialyzer still reports existing baseline project warnings)
