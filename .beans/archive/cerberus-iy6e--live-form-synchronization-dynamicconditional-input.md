---
# cerberus-iy6e
title: 'Live form synchronization: dynamic/conditional inputs and dispatch(change)'
status: completed
type: bug
priority: normal
created_at: 2026-02-27T21:48:03Z
updated_at: 2026-02-28T05:55:58Z
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
- [x] Expand fixtures for dynamic add/remove + conditional field removal + no-phx-change submit
- [x] Add failing browser-oracle conformance tests for stale-field submission
- [x] Align active_form/form_data pruning + dispatch(change) handling
- [x] Validate fixes across static/live/browser drivers

## Triage Note
This candidate comes from an upstream phoenix_test issue or PR and may already work in Cerberus.
If current Cerberus behavior already matches the expected semantics, add or keep the conformance test coverage and close this bean as done (no behavior change required).

## Summary of Changes
- Added live fixture /live/form-sync for conditional fields, dynamic add/remove via JS.dispatch("change"), and submit-only phx-submit behavior.
- Added static fixture routes /search/profile/a, /search/profile/b, and /search/profile/results to assert stale-field pruning across static/browser.
- Added cross-driver conformance coverage in test/core/live_form_synchronization_conformance_test.exs for live/browser and static/browser parity.
- Updated live/static payload assembly to prune active form_data to currently rendered, submittable field names before change/submit.
- Added Html.form_field_names/3 and live-click metadata handling so form-scoped dispatch(change) buttons are actionable in the live driver.
- Fixed scoped form lookup regression for within("#form-id") by handling form-self selector resolution in HTML helpers.
- Added HTML unit coverage for dispatch(change) discovery and form-field-name extraction.
- Validation: mix test (175 tests, 0 failures) and mix precommit both pass.
