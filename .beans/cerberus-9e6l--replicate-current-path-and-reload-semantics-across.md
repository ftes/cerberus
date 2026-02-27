---
# cerberus-9e6l
title: Replicate current_path and reload semantics across LiveView transitions
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T12:16:01Z
parent: cerberus-zqpu
---

## Scope
Replicate consistent `current_path` tracking across visit, href navigation, live navigate/patch, push navigate/patch, and page reload.

## PhoenixTest Source Snippet
`/tmp/phoenix_test/test/phoenix_test/live_test.exs`

```elixir
test "it is updated on live patching", %{conn: conn} do
  session =
    conn
    |> visit("/live/index")
    |> click_link("Patch link")

  assert PhoenixTest.Driver.current_path(session) == "/live/index?details=true&foo=bar"
end

test "it is updated on push navigation", %{conn: conn} do
  session =
    conn
    |> visit("/live/index")
    |> click_button("Button with push navigation")

  assert PhoenixTest.Driver.current_path(session) == "/live/page_2?foo=bar"
end

test "preserves current path", %{conn: conn} do
  conn
  |> visit("/live/index")
  |> reload_page()
  |> assert_path("/live/index")
end
```

## Done When
- [x] Cerberus exposes deterministic current-path semantics after each navigation mode.
- [x] Query strings are preserved in path tracking.
- [x] Reload keeps path consistent and covered by tests.

## Summary of Changes
- Added public `reload_page/2` API in `Cerberus` that revisits `session.current_path` (or `/` if unset), giving deterministic reload semantics across drivers.
- Extended `Cerberus.Fixtures.RedirectsLive` with explicit live patch and push navigation actions plus `handle_params/3` required for patch transitions.
- Added fixture constants for patch/navigation path expectations and button labels in `Cerberus.Fixtures`.
- Updated live driver button click handling to preserve `current_path` after patch transitions by consuming pending patch navigation events when present.
- Added cross-driver conformance coverage in `test/core/current_path_test.exs` for:
  - live patch current-path updates,
  - push navigation current-path updates,
  - query-string preservation,
  - reload path preservation after patch transitions.
- Added public API coverage for `reload_page/1` in `test/cerberus/public_api_test.exs`.
- Validation:
  - `mix test test/cerberus/public_api_test.exs test/core/current_path_test.exs`
  - `mix test` (full suite) -> `34 tests, 0 failures`
  - `mix credo --strict` on touched files.
