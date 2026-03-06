---
# cerberus-ntw8
title: Confirm locator_parity selector rejection expectation
status: completed
type: task
priority: normal
created_at: 2026-03-06T10:19:12Z
updated_at: 2026-03-06T10:23:45Z
---

## Goal
Confirm whether locator_parity_test.exs line 399 should fail now that selector option was removed.

## Todo
- [x] Inspect the referenced test case and expected outcome
- [x] Reply to user with exact behavior

## Summary of Changes
- Confirmed the parity corpus case at test/cerberus/locator_parity_test.exs line 399 is intentionally an error case with expect set to :error.
- Verified assert_has/3 validates options through Cerberus.Options.validate_assert!/2.
- Reproduced validation behavior directly: Cerberus.Options.validate_assert! with selector option raises ArgumentError for unknown option :selector.
- Confirmed the parity harness wraps each call via run_case/2, catches ArgumentError, and records status :error; that is why the test passes when the call fails.
