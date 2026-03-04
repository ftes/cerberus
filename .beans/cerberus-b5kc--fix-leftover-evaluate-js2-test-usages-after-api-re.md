---
# cerberus-b5kc
title: Fix leftover evaluate_js/2 test usages after API removal
status: completed
type: bug
priority: normal
created_at: 2026-03-04T11:40:59Z
updated_at: 2026-03-04T11:42:07Z
---

Compilation fails because some tests still call removed evaluate_js/2.\n\n- [x] Find remaining evaluate_js/2 calls\n- [x] Update call sites to evaluate_js/3 callback form\n- [x] Run targeted tests for impacted modules\n- [x] Add summary and mark completed

## Summary of Changes
- Fixed the remaining evaluate_js/2 call in test/cerberus/browser_iframe_limitations_test.exs by converting it to evaluate_js/3 with a no-op callback.
- Verified no other evaluate_js/2 usages remain in tests/docs/bench via repo-wide search.
- Validation: PORT=4012 mix test test/cerberus/browser_iframe_limitations_test.exs (4 tests, 0 failures).
