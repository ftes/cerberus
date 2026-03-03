---
# cerberus-42ko
title: Speed up browser harness tests via shared sessions
status: completed
type: task
priority: normal
created_at: 2026-03-03T10:12:52Z
updated_at: 2026-03-03T10:15:37Z
---

Reduce startup overhead in unit-style browser harness tests by reusing a shared browser user context/session instead of creating a fresh session per test case.\n\nScope:\n- [x] Audit candidate harness modules and select low-risk targets\n- [x] Add shared-browser-session setup helper flow in selected tests\n- [x] Update tests to use shared browser session while keeping Phoenix lane behavior\n- [x] Validate with focused suites and precommit\n- [x] Commit code + bean

## Summary of Changes

Optimized unit-style browser harness tests by reusing a single browser session per module instead of creating a new browser user context for every test case.

Changes:
- Updated test/cerberus/helper_locator_behavior_test.exs
  - Added module-level shared browser session bootstrap/teardown.
  - Kept per-test API shape and assertions unchanged.
  - Browser lane now reuses one session via context helper; Phoenix lane still creates fresh `session(:phoenix)` per test.
- Updated test/cerberus/within_closest_behavior_test.exs
  - Applied the same shared-browser-session pattern.

Validation:
- source .envrc && mix format
- source .envrc && mix test test/cerberus/helper_locator_behavior_test.exs test/cerberus/within_closest_behavior_test.exs
- source .envrc && mix test test/cerberus/locator_test.exs test/cerberus/helper_locator_behavior_test.exs test/cerberus/locator_parity_test.exs test/cerberus/within_closest_behavior_test.exs
- source .envrc && mix precommit

Observed impact in focused composition suite run:
- Before shared-session changes: 67 tests in ~59.0s
- After shared-session changes: 67 tests in ~43.6s
