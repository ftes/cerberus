---
# cerberus-fbxp
title: Fix live uncheck empty checkbox value in EV2 custom documents
status: completed
type: bug
priority: normal
created_at: 2026-03-04T20:57:05Z
updated_at: 2026-03-04T21:00:59Z
---

EV2 custom_documents uncheck fails in live driver: checkbox value passed as empty string, but LV expects false/true. Trace apply_live_checkbox_change path and fix value extraction/normalization.

\n## Summary of Changes\n- Fixed checkbox uncheck value resolution for boolean fields by using the hidden input value (if present) from the same form instead of falling back to an empty string.\n- Added Html.checkbox_unchecked_value helper to resolve hidden checkbox defaults for both in-form and owner-form controls.\n- Updated live and static FormData.toggled_checkbox_value to use this hidden unchecked value fallback.\n- Added regression tests:\n  - HtmlTest for hidden checkbox unchecked value lookup.\n  - Live.FormDataTest for toggled_checkbox_value returning false for checked boolean checkbox uncheck.\n- Verification:\n  - PORT=4621 mix test test/cerberus/driver/html_test.exs test/cerberus/driver/live/form_data_test.exs\n  - PORT=4644 mix test test/cerberus/checkbox_array_behavior_test.exs\n  - cd ../ev2 and PORT=4629 mix test test/ev2_web/admin/pages/custom_documents_live/index_test.exs:41\n  - cd ../ev2 and PORT=4637 mix test test/ev2_web/admin/pages/custom_documents_live/index_test.exs
