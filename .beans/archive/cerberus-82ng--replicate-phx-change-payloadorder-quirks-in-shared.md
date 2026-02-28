---
# cerberus-82ng
title: Replicate phx-change payload/order quirks in shared form helpers
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T21:39:57Z
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
- [x] `fill_in/select/check/choose/upload` trigger `phx-change` only when appropriate.
- [x] `_target` semantics are represented in the payload.
- [x] Active form bookkeeping is ordered correctly to avoid hidden-input race regressions.

## Summary of Changes
- Implemented live-route `fill_in/4` `phx-change` support in `Cerberus.Driver.Live`:
  - triggers change events only when input/form has `phx-change`,
  - emits `_target` as path list derived from the field name,
  - updates active form data before payload construction.
- Added form payload construction that merges active values with form defaults
  (including hidden inputs), preventing hidden-field race regressions.
- Extended HTML field metadata extraction in `Cerberus.Driver.Html` with
  `selector`, `form_selector`, and `phx-change` flags, plus form-default
  extraction helper used by live change payloads.
- Added new live fixture route/page for `phx-change` semantics:
  - `/live/form-change`
  - fixture module `Cerberus.Fixtures.FormChangeLive`.
- Added cross-driver conformance coverage (`:live` vs `:browser`) for:
  - `_target` payload behavior,
  - no-change behavior when `phx-change` is absent,
  - active-form ordering with hidden input preservation.
- Updated existing live form-action expectation test to reflect new live
  `fill_in` behavior and retained explicit live-submit unsupported semantics.
