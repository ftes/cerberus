---
# cerberus-82ng
title: Replicate phx-change payload/order quirks in shared form helpers
status: todo
type: task
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T11:31:31Z
parent: cerberus-zqpu
---

## Scope
Replicate shared form helper quirks around `phx-change`: validation triggering, `_target` payload emission, and ordering correctness between active form state and payload updates.

## PhoenixTest Source Snippet
`/tmp/phoenix_test/test/phoenix_test/live_test.exs`

```elixir
test "sends _target with phx-change events", %{conn: conn} do
  conn
  |> visit("/live/index")
  |> fill_in("Email", with: "frodo@example.com")
  |> assert_has("#form-data", text: "_target: [email]")
end

test "does not trigger phx-change event if one isn't present", %{conn: conn} do
  session = visit(conn, "/live/index")

  starting_html = Driver.render_html(session)

  ending_html =
    session
    |> within("#no-phx-change-form", &fill_in(&1, "Name", with: "Aragorn"))
    |> Driver.render_html()

  assert Html.element(starting_html) == Html.element(ending_html)
end

test "preserves correct order of active form vs form data", %{conn: conn} do
  conn
  |> visit("/live/index")
  |> within("#changes-hidden-input-form", fn session ->
    session
    |> fill_in("Name for hidden", with: "Frodo")
    |> fill_in("Email for hidden", with: "frodo@example.com")
  end)
  |> assert_has("#form-data", text: "name: Frodo")
  |> assert_has("#form-data", text: "email: frodo@example.com")
  |> assert_has("#form-data", text: "hidden_race: hobbit")
end
```

## Done When
- [ ] `fill_in/select/check/choose/upload` trigger `phx-change` only when appropriate.
- [ ] `_target` semantics are represented in the payload.
- [ ] Active form bookkeeping is ordered correctly to avoid hidden-input race regressions.
