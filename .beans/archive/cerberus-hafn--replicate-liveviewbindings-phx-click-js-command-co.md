---
# cerberus-hafn
title: Replicate LiveViewBindings phx-click JS-command compatibility
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T18:58:29Z
parent: cerberus-zqpu
---

## Scope
Replicate `phx-click` binding detection parity for raw handlers and JS-command handlers (`push`, `navigate`, `patch`) while excluding unsupported JS actions (`dispatch`).

## PhoenixTest Source Snippet
`/tmp/phoenix_test/test/phoenix_test/live_view_bindings_test.exs`

```elixir
test "returns true if JS command is a push (LiveViewTest can handle)" do
  html = rendered_to_string(~H"""
  <input phx-click={JS.push("save")} />
  """)

  element = html |> Html.parse_fragment() |> Html.all("input")
  assert LiveViewBindings.phx_click?(element)
end

test "returns true if JS command is a patch (LiveViewTest can handle)" do
  html = rendered_to_string(~H"""
  <div phx-click={JS.patch("/some/path")}></div>
  """)

  element = html |> Html.parse_fragment() |> Html.all("div")
  assert LiveViewBindings.phx_click?(element)
end

test "returns false if JS command is a dispatch" do
  html = rendered_to_string(~H"""
  <input phx-click={JS.dispatch("change")} />
  """)

  element = html |> Html.parse_fragment() |> Html.all("input")
  refute LiveViewBindings.phx_click?(element)
end
```

## Done When
- [x] Cerberus action detection supports JS push/navigate/patch click semantics.
- [x] Unsupported JS-only client actions (dispatch-only) are not treated as actionable server events.
- [x] Coverage includes mixed command pipelines.

## Summary of Changes

- Added `Cerberus.LiveViewBindings.phx_click?/1` to classify raw `phx-click` handlers and JS command payloads, accepting `push`/`navigate`/`patch` and rejecting `dispatch`-only commands.
- Added `Cerberus.Driver.Html.find_live_clickable_button/4` and wired live-driver button resolution to use it in live mode, so dispatch-only buttons are excluded from server-actionable `render_click` resolution.
- Extended `/live/redirects` fixture with JS-command `phx-click` buttons (push, navigate, patch, dispatch+push, dispatch-only).
- Added tests:
  - `test/cerberus/live_view_bindings_test.exs` for binding parser behavior.
  - `test/core/live_click_bindings_conformance_test.exs` for live/browser actionable JS command conformance and live-only dispatch exclusion.
- Updated docs in `README.md` and `docs/fixtures.md`.

## Validation

- `mix test test/cerberus/live_view_bindings_test.exs test/core/live_click_bindings_conformance_test.exs test/core/live_navigation_test.exs` (pass)
- `mix precommit` (credo pass; dialyzer reports existing baseline warnings outside this slice)
