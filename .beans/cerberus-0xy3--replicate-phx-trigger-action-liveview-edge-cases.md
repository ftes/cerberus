---
# cerberus-0xy3
title: Replicate phx-trigger-action LiveView edge cases
status: todo
type: task
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T11:31:31Z
parent: cerberus-zqpu
---

## Scope
Replicate `phx-trigger-action` edge behavior: static POST handoff, trigger-from-outside-form, trigger-after-patch, ignore-on-redirect/navigate, multi-trigger erroring, and dynamically rendered forms.

## PhoenixTest Source Snippet
`/tmp/phoenix_test/test/phoenix_test/live_test.exs`

```elixir
test "phx-trigger-action causes POST to static view", %{conn: conn} do
  conn
  |> visit("/live/index")
  |> fill_in("Trigger action", with: "engage")
  |> submit()
  |> assert_has("#form-data", text: "trigger_action_hidden_input: trigger_action_hidden_value")
  |> assert_has("#form-data", text: "trigger_action_input: engage")
end

test "phx-trigger-action performed after patch", %{conn: conn} do
  conn
  |> visit("/live/index")
  |> fill_in("Patch and trigger action", with: "let's go")
  |> assert_path("/page/create_record")
end

test "raises an error if multiple forms have phx-trigger-action", %{conn: conn} do
  assert_raise ArgumentError, ~r/Found multiple forms/, fn ->
    conn
    |> visit("/live/index")
    |> click_button("Trigger multiple")
    |> assert_has("#form-data", text: "hidden: trigger_action_hidden_value")
  end
end
```

## Done When
- [ ] Cerberus reproduces trigger-action handoff to static views.
- [ ] Trigger-action sequencing with patch/redirect/navigate is deterministic and tested.
- [ ] Multiple-trigger ambiguity raises a clear error.
- [ ] Dynamic-form trigger-action behavior is covered.
