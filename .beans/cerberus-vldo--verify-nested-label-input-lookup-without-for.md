---
# cerberus-vldo
title: Verify nested label input lookup without for
status: completed
type: task
priority: normal
created_at: 2026-03-05T05:48:29Z
updated_at: 2026-03-05T05:50:22Z
---

Confirm whether input lookup correctly resolves controls nested inside <label> elements that do not use a for attribute. Record code path and test evidence.

## Summary of Changes

- Verified implementation in  resolves field labels via both  and wrapped-label fallback ().
- Verified browser helper in  resolves wrapped labels via  fallback.
- Ran targeted regression tests with random port () after :
  - 
  - 
  - 
- Result: 5 tests run, 0 failures.

## Summary of Changes (Corrected)

- Verified implementation in lib/cerberus/html/html.ex resolves field labels via both label-for lookup and wrapped-label fallback using wrapping_label_for_control/2.
- Verified browser helper in lib/cerberus/driver/browser/action_helpers.ex resolves wrapped labels via element.closest("label") fallback.
- Ran targeted regression tests with random port PORT=4127 after source .envrc:
  - test/cerberus/form_actions_test.exs:49
  - test/cerberus/live_form_change_behavior_test.exs:52
  - test/cerberus/locator_parity_test.exs:421
- Result: 5 tests run, 0 failures.
