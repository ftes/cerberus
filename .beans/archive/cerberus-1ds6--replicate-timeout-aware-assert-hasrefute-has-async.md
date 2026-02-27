---
# cerberus-1ds6
title: Replicate timeout-aware assert_has/refute_has async semantics
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T19:22:12Z
parent: cerberus-zqpu
---

## Scope
Replicate timeout-aware `assert_has/refute_has` semantics for asynchronous assigns, info-message updates, async navigations, and redirects across one or multiple LiveViews.

## PhoenixTest Source Snippet
`/tmp/phoenix_test/test/phoenix_test/live_test.exs`

```elixir
test "timeout waits for async assigns", %{conn: conn} do
  conn
  |> visit("/live/async_page")
  |> assert_has("h1", text: "Title loaded async", timeout: 350)
end

test "timeout handles async navigates", %{conn: conn} do
  conn
  |> visit("/live/async_page")
  |> click_button("Async navigate!")
  |> assert_has("h1", text: "LiveView page 2", timeout: 250)
end

test "can handle multiple LiveViews (redirect one to another) with async behavior", %{conn: conn} do
  conn
  |> visit("/live/async_page")
  |> click_button("Async navigate to async 2 page!")
  |> assert_has("h1", text: "Another title loaded async", timeout: 250)
end

test "timeout handles redirects", %{conn: conn} do
  conn
  |> visit("/live/async_page")
  |> click_button("Async redirect!")
  |> refute_has("h2", text: "Where we test LiveView's async behavior", timeout: 250)
end
```

## Done When
- [x] Timeout polling behavior is deterministic and configurable.
- [x] Redirect/navigate transitions during waits are handled without flakiness.
- [x] Multi-live async transitions are covered in integration tests.

## Summary of Changes
- Added timeout option support to assertion options (`assert_has/3`, `refute_has/3`) and wired those operations through `Cerberus.LiveViewTimeout.with_timeout/4`.
- Updated `Cerberus.LiveViewTimeout` with a non-live fallback clause so timeout wrapping is safe for browser and other non-live session structs.
- Added async fixture live views and routes for deterministic timeout behavior testing:
  - `/live/async_page`
  - `/live/async_page_2`
- Added live conformance coverage in `test/core/live_timeout_assertions_test.exs` for async assign wait, async navigate, async multi-live transition, and async redirect/refute flows.
- Added public API coverage for timeout option validation and documented timeout-aware live assertions in README.

## Validation
- `mix test test/core/live_timeout_assertions_test.exs test/cerberus/public_api_test.exs test/cerberus/live_view_timeout_test.exs test/cerberus/live_view_watcher_test.exs`
- `mix test test/core/live_navigation_test.exs test/core/live_link_navigation_test.exs test/core/live_click_bindings_conformance_test.exs`
- `mix precommit` (Credo passes; Dialyzer still reports existing baseline project warnings)
