---
# cerberus-294u
title: Replicate LiveView button/form ownership and active-form quirks
status: in-progress
type: task
priority: normal
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T12:18:34Z
parent: cerberus-zqpu
---

## Scope
Replicate button/form oddities: active form lifecycle, button name/value submission semantics, owner-form submission where button is outside form, and redirect handling with headers.

## PhoenixTest Source Snippet
`/tmp/phoenix_test/test/phoenix_test/live_test.exs`

```elixir
test "does not remove active form if button isn't form's submit button", %{conn: conn} do
  session =
    conn
    |> visit("/live/index")
    |> fill_in("User Name", with: "Aragorn")
    |> click_button("Reset")

  assert PhoenixTest.ActiveForm.active?(session.active_form)
end

test "resets active form if it is form's submit button", %{conn: conn} do
  session =
    conn
    |> visit("/live/index")
    |> fill_in("User Name", with: "Aragorn")
    |> click_button("Save Nested Form")

  refute PhoenixTest.ActiveForm.active?(session.active_form)
end

test "submits owner form if button isn't nested inside form (including button data)", %{conn: conn} do
  conn
  |> visit("/live/index")
  |> within("#owner-form", fn session ->
    fill_in(session, "Name", with: "Aragorn")
  end)
  |> click_button("Save Owner Form")
  |> assert_has("#form-data", text: "name: Aragorn")
  |> assert_has("#form-data", text: "form-button: save-owner-form")
end
```

## Done When
- [ ] Non-submit buttons do not clear active form state.
- [ ] Submit buttons clear active form state and include button payload semantics.
- [ ] `button[form=...]` owner-form behavior is covered in integration tests.
- [ ] Redirect + header preservation cases are added for button-driven submit paths.
