---
# cerberus-8i92
title: Debug ev2-copy Firefox login submit failure
status: completed
type: bug
priority: normal
created_at: 2026-03-12T09:47:52Z
updated_at: 2026-03-12T10:20:53Z
---

Reproduce the ev2-copy Firefox browser test failure that currently shows up as assert_path after login, determine whether the issue is in Cerberus fill/click/submit behavior or app-specific page behavior, patch the smallest correct fix, and verify with focused Firefox repros.

## Summary of Changes

- Reproduced the EV2 Firefox failure and confirmed the login form submitted successfully; the failing  was caused by Cerberus path assertions falling back to  after a transient browser-evaluation error without re-checking whether that fallback path actually satisfied the assertion.
- Patched Cerberus browser path assertions to evaluate the fallback path semantically for both  and .
- Added a deterministic browser regression test that forces a transient  path-helper failure and now passes.
- Verified the fix in Cerberus on both Chrome and Firefox, and verified the EV2 Firefox TFA flow now passes.

## Clarifying Notes

- The failing login assertion was assert_path slash after login.
- The fallback path was current_path.
- The patched operations were assert_path and refute_path.
- The transient browser error reproduced as Execution context was destroyed.
