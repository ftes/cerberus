---
# cerberus-7ak7
title: Replicate LiveViewTimeout retry and redirect-resilience behavior
status: todo
type: task
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T11:31:31Z
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
- [ ] Timeout loop retries failed assertions/actions until timeout.
- [ ] Redirect notifications from watcher are applied during retries.
- [ ] Dead-view fallback attempts redirect using provided redirect resolver.
