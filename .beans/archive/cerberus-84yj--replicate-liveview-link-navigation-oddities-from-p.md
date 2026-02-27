---
# cerberus-84yj
title: Replicate LiveView link navigation oddities from phoenix_test
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T18:24:00Z
parent: cerberus-zqpu
---

## Scope
Replicate LiveView link navigation behavior parity across navigate/patch/non-live transitions and ensure request headers survive driver transitions.

## PhoenixTest Source Snippet
`/tmp/phoenix_test/test/phoenix_test/live_test.exs`

```elixir
test "follows navigation that subsequently redirect", %{conn: conn} do
  conn
  |> visit("/live/index")
  |> click_link("Navigate (and redirect back) link")
  |> assert_has("h1", text: "LiveView main page")
  |> assert_has("#flash-group", text: "Navigated back!")
end

test "handles patches to current view", %{conn: conn} do
  conn
  |> visit("/live/index")
  |> click_link("Patch link")
  |> assert_has("h2", text: "LiveView main page details")
end

test "preserves headers across navigation", %{conn: conn} do
  conn
  |> Plug.Conn.put_req_header("x-custom-header", "Some-Value")
  |> visit("/live/index")
  |> click_link("Navigate to non-liveview")
  |> assert_has("h1", text: "Main page")
  |> then(fn %{conn: conn} ->
    assert {"x-custom-header", "Some-Value"} in conn.req_headers
  end)
end
```

## Done When
- [x] Cerberus click-link flow handles live navigate, patch, and non-live transitions.
- [x] Flash/assertion parity is covered for navigate-then-redirect behavior.
- [x] Header preservation is validated in integration coverage.

## Summary of Changes
- Added live-link parity fixtures on /live/redirects for navigate, patch, redirect-back, and non-live transitions.
- Added /main static fixture page that echoes x-custom-header and added conformance coverage for header preservation with seeded conn session opts.
- Updated live driver link click handling to attempt LiveView render_click first (with redirect/patch handling) and fallback to href visit when needed.
- Added cross-driver conformance tests in test/core/live_link_navigation_test.exs for live+browser navigation parity and live-only header preservation.
- Updated fixture docs route surface for the new navigation fixtures.
