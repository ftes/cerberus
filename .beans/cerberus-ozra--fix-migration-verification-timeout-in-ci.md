---
# cerberus-ozra
title: Fix migration verification timeout in CI
status: completed
type: bug
priority: normal
created_at: 2026-02-28T19:40:12Z
updated_at: 2026-02-28T19:42:58Z
parent: cerberus-it5x
---

Migration verification step timed out in CI because the end-to-end fixture parity test runs many row-by-row `mix test` invocations and exceeded ExUnit's default per-test timeout in slower CI environments.

## Todo
- [x] Reproduce timeout locally with migration verification test path used in CI.
- [x] Identify root cause in runner/execution strategy.
- [x] Implement fix to avoid CI timeout while preserving coverage scope.
- [x] Validate with targeted and full migration verification runs.
- [x] Update docs/config if behavior changed.

## Summary of Changes
- Added `@tag timeout: 180_000` to `test "runs end-to-end against committed migration fixture"` in `test/cerberus/migration_verification_test.exs`.
- Kept migration coverage and row set unchanged; only adjusted timeout budget for this long-running integration test.
- Verified with `mix test --only migration_verification` (all tests passing).

## Notes
- No docs/config updates were required because this is internal test-timeout handling.
