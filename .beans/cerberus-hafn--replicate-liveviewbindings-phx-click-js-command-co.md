---
# cerberus-hafn
title: Replicate LiveViewBindings phx-click JS-command compatibility
status: todo
type: task
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T11:31:31Z
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
- [ ] Cerberus action detection supports JS push/navigate/patch click semantics.
- [ ] Unsupported JS-only client actions (dispatch-only) are not treated as actionable server events.
- [ ] Coverage includes mixed command pipelines.
