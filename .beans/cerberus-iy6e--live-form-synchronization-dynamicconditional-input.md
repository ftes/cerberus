---
# cerberus-iy6e
title: 'Live form synchronization: dynamic/conditional inputs and dispatch(change)'
status: todo
type: bug
priority: normal
created_at: 2026-02-27T21:48:03Z
updated_at: 2026-02-27T22:35:41Z
parent: cerberus-zqpu
---

Sources:
- https://github.com/germsvel/phoenix_test/issues/216
- https://github.com/germsvel/phoenix_test/pull/300
- https://github.com/germsvel/phoenix_test/pull/297
- https://github.com/germsvel/phoenix_test/issues/203
- https://github.com/germsvel/phoenix_test/issues/238

Problem group:
Live form state can desync from rendered inputs when using dynamic/conditional fields.
Reported effects include stale values being submitted, incorrect drop/sort params, and JS.dispatch("change") button behavior not matching browser semantics.

Upstream failing/repro tests:

```elixir
# #300
test "handles dynamic add/remove buttons without a `form` attribute", %{conn: conn} do
  conn
  |> visit("/live/dynamic_inputs_add_remove")
  |> assert_has("#mailing_list_emails_0_email")
  |> click_button("add more")
  |> assert_has("#mailing_list_emails_1_email")
  |> click_button("button[name='mailing_list[emails_drop][]'][value='1']", "delete")
  |> refute_has("#mailing_list_emails_1_email")
end
```

```elixir
# #297
test "submitting after switching versions only includes the visible field", %{conn: conn} do
  conn
  |> visit("/live/conditional_form")
  |> fill_in("Version A Text", with: "some value for A")
  |> select("Version", option: "Version B")
  |> fill_in("Version B Text", with: "some value for B")
  |> click_button("Save")
  |> refute_has("#form-data", text: "version_a_text")
end
```

Expected Cerberus parity checks:
- only currently rendered/named fields are submitted
- JS.dispatch("change") inside forms triggers form-change semantics
- nested inputs_for drop/sort params align with browser submissions

## Todo
- [ ] Expand fixtures for dynamic add/remove + conditional field removal + no-phx-change submit
- [ ] Add failing browser-oracle conformance tests for stale-field submission
- [ ] Align active_form/form_data pruning + dispatch(change) handling
- [ ] Validate fixes across static/live/browser drivers

## Triage Note
This candidate comes from an upstream phoenix_test issue or PR and may already work in Cerberus.
If current Cerberus behavior already matches the expected semantics, add or keep the conformance test coverage and close this bean as done (no behavior change required).
