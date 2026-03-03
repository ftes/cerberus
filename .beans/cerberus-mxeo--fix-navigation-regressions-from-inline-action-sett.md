---
# cerberus-mxeo
title: Fix navigation regressions from inline action settle
status: completed
type: bug
priority: normal
created_at: 2026-03-03T14:51:43Z
updated_at: 2026-03-03T14:52:58Z
---

Resolve browser click/submit regressions (inspected target navigated or closed, stale current_path) introduced by inline settle/conditional await logic. Ensure click/submit always preserve navigation correctness and rerun failing suites.

## Summary of Changes
- Root cause confirmed: inline post-click/post-submit settle wait in action helper kept evaluate command alive across navigation boundaries, producing Inspected target navigated or closed failures.
- Root cause confirmed: conditional skip of await_ready for click/submit could misclassify live patch/navigate flows and leave current_path stale.
- Fixed by forcing needsAwaitReady true for click and submit in action helper.
- Fixed by restricting in-helper settle wait to non-navigation form operations only (fill_in/select/choose/check/uncheck/upload).
- Updated browser_action_settle_behavior_test to assert click/submit still await readiness (non-synthetic readiness payload).
- Verified with source .envrc && mix test test/cerberus/live_navigation_test.exs test/cerberus/current_path_test.exs test/cerberus/live_trigger_action_behavior_test.exs test/cerberus/browser_action_settle_behavior_test.exs (28 tests, 0 failures).
- Added repeat check: source .envrc && mix test test/cerberus/live_navigation_test.exs test/cerberus/current_path_test.exs test/cerberus/live_trigger_action_behavior_test.exs executed 3 times, all passing.
