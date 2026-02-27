---
# cerberus-1ds6
title: Replicate timeout-aware assert_has/refute_has async semantics
status: todo
type: task
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T11:31:31Z
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
- [ ] Timeout polling behavior is deterministic and configurable.
- [ ] Redirect/navigate transitions during waits are handled without flakiness.
- [ ] Multi-live async transitions are covered in integration tests.
