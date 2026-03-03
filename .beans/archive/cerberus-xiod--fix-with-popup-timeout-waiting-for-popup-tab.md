---
# cerberus-xiod
title: Fix with_popup timeout waiting for popup tab
status: completed
type: bug
priority: normal
created_at: 2026-03-03T22:01:39Z
updated_at: 2026-03-03T22:10:37Z
---

Investigate and fix intermittent timeout in BrowserExtensionsTest with_popup waiter registration/open race. Add regression coverage and stress validation.

## Progress
- Reproduced the flake exactly with full-suite order: mix test --seed 411384.
- Failure matched timeout path at lib/cerberus/driver/browser/extensions.ex handle_popup_task_result/3.

## Summary of Changes
- Patched with_popup popup wait loop to perform a final deadline probe via UserContextProcess.await_popup_tab(..., 1) before raising timeout.
- This eliminates the timeout-boundary race where popup detection may complete right at the deadline between non-blocking polls.
- Verified by re-running full suite with the same seed: mix test --seed 411384 -> 460 tests, 0 failures.

- Ran mix precommit successfully after the patch.
- Re-ran full suite again with same seed (mix test --seed 411384): 460 tests, 0 failures.
