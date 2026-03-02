---
# cerberus-mqhy
title: Expand with_dialog tests for message match and timeout/error branches
status: completed
type: task
priority: normal
created_at: 2026-02-28T15:08:23Z
updated_at: 2026-03-02T05:51:47Z
---

Missing-tests follow-up: with_dialog coverage is mostly happy-path today.

## Scope
- Add tests for message mismatch assertions
- Add tests for timeout behavior
- Add tests for callback return validation/errors

## Acceptance
- with_dialog behavior branches are covered and stable


## Todo
- [x] Add message mismatch assertion coverage for with_dialog
- [x] Add timeout branch coverage for with_dialog
- [x] Add callback return validation and error propagation coverage
- [x] Run format, focused tests, and precommit
- [x] Summarize and complete bean


## Summary of Changes
- Expanded with_dialog coverage with tests for expected-message mismatch assertions.
- Added deterministic timeout coverage for prompt-open wait behavior.
- Added callback validation coverage for invalid callback return types.
- Added callback error propagation coverage and fixed with_dialog task-link handling so callback crashes are surfaced as assertion errors rather than crashing the caller process.
- Verified with mix format, focused warning-as-error test runs, and mix precommit.
