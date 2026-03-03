---
# cerberus-89ej
title: Assess static/live locator performance and LazyHTML opportunities
status: completed
type: task
priority: normal
created_at: 2026-03-03T14:26:40Z
updated_at: 2026-03-03T14:36:15Z
---

Analyze current static/live locator-resolution and HTML operation performance paths.\n\nScope:\n- [ ] Trace current static and live locator resolution/action/assertion call flow.\n- [ ] Identify parse/selection hot paths and repeated DOM work.\n- [ ] Evaluate where LazyHTML primitives can replace slower custom/filter passes.\n- [ ] Provide concrete optimization plan with expected impact and risk.\n- [x] Add summary of findings.

## Summary of Changes
- Added parsed-document overloads in Cerberus.Html for texts/assertion_values/find_form_field/find_submit_button/form_defaults so callers can avoid repeated LazyHTML.from_document parsing.
- Updated Cerberus.Phoenix.LiveViewHTML to parse once per operation and pass parsed docs through Html helpers (find_form_field/find_submit_button/trigger_action_forms).
- Removed repeated parse-per-form path in trigger_action defaults by calling Html.form_defaults on the already parsed root.
- Replaced common id lookup scans with LazyHTML.query_by_id in Html and LiveViewHTML helper paths.
- Replaced node tag/attribute extraction via LazyHTML.to_tree with LazyHTML.tag/LazyHTML.attributes in Html and LiveViewHTML.
- Added regression coverage for pre-parsed document resolver APIs and ran targeted + broader locator/ownership tests.

Validation:
- source .envrc && mix test test/cerberus/driver/html_test.exs
- source .envrc && mix test test/cerberus/phoenix/live_view_html_test.exs
- source .envrc && mix test test/cerberus/form_button_ownership_test.exs test/cerberus/locator_parity_test.exs
