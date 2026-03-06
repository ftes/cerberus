---
# cerberus-30m8
title: Audit missing assert/refute helpers
status: completed
type: task
priority: normal
created_at: 2026-03-06T13:04:47Z
updated_at: 2026-03-06T13:06:40Z
---

Identify which assert/refute helper functions are currently missing from Cerberus API and tests, including checked/selected/disabled style predicates.

## Summary of Changes
- Audited public assertion APIs in lib/cerberus.ex and lib/cerberus/browser.ex.
- Confirmed existing assert/refute functions: assert_has/refute_has, assert_value/refute_value, assert_path/refute_path, plus assert_download and Browser.assert_dialog.
- Verified no dedicated assert_checked/refute_checked-style helpers currently exist in code or tests.
- Verified assertion option surface: assert_has supports visibility/match/count filters only; assert_value supports state filters (checked/disabled/selected/readonly).
