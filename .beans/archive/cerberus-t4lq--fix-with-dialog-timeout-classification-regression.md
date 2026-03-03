---
# cerberus-t4lq
title: Fix with_dialog timeout classification regression
status: completed
type: bug
priority: normal
created_at: 2026-03-02T14:03:35Z
updated_at: 2026-03-02T14:14:29Z
---

Investigate BrowserExtensionsTest failure where with_dialog timeout path raises ArgumentError instead of AssertionError when BiDi command times out.

- [x] Reproduce failure locally
- [x] Identify regression point in with_dialog timeout/open-event fallback
- [x] Implement fix to preserve assertion-timeout semantics
- [x] Run format and targeted tests
- [x] Run precommit
- [x] Update bean summary and status

## Summary of Changes

- Confirmed this is the same failure family as prior with_dialog race fixes: missing open-event fallback path could raise ArgumentError when the fallback BiDi probe timed out.
- Updated maybe_handle_prompt_without_open_event!/2 to classify no-alert and timeout-like fallback probe errors as :not_open, so control returns to the existing assertion-timeout branch.
- Preserved strict ArgumentError behavior for non-timeout/non-no-alert fallback failures.
- Validation: single targeted run at line 279 (pass), 80-run stress loop for line 279 (LOOP_OK), full browser_extensions_test module (13 tests pass), mix format, and mix precommit (pass).
