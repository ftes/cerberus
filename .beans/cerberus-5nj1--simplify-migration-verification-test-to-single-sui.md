---
# cerberus-5nj1
title: Simplify migration verification test to single suite pass
status: completed
type: task
priority: normal
created_at: 2026-03-01T06:53:49Z
updated_at: 2026-03-01T06:59:09Z
---

Replace migration verification matrix assertions with one end-to-end test that runs the full sample suite pre-migration and post-migration.

## Todo
- [x] Review existing migration verification test structure and helpers
- [x] Implement single-test flow (run suite, migrate, rerun suite)
- [x] Run formatting and targeted tests
- [x] Update bean with summary and mark completed

## Summary of Changes
- Simplified `test/cerberus/migration_verification_test.exs` to a single end-to-end test that runs pre-migration tests, applies migration, and reruns tests post-migration.
- Switched the single verification row to a migration-ready suite target pattern (`test/features/pt_*_test.exs`) so the run stays one-command-per-phase while covering all migration scenarios together.
- Enhanced `Cerberus.MigrationVerification` to support directory/glob migration targets and to expand wildcard test targets into concrete files before invoking `mix test`.
- Updated the fixture multi-user tab scenario to remain compile-safe in phoenix mode while still exercising tab/user APIs in cerberus mode.
- Updated `docs/migration-verification.md` to describe the new single-row full-suite verification flow.
- Verified with `mix test test/cerberus/migration_verification_test.exs` and `mix precommit`.
