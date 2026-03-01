---
# cerberus-8do5
title: Remove migration verification helper from lib and run mix task directly in test
status: completed
type: task
priority: normal
created_at: 2026-03-01T07:05:03Z
updated_at: 2026-03-01T07:07:16Z
---

Move migration verification orchestration out of runtime lib code and simplify migration verification test to call mix commands directly.

## Todo
- [x] Audit current helper usage and dependencies
- [x] Rewrite migration verification test to run full flow directly
- [x] Remove helper module from lib and clean docs references
- [x] Run format and targeted checks
- [x] Update bean summary and complete

## Summary of Changes
- Rewrote `test/cerberus/migration_verification_test.exs` to run the migration verification flow directly with mix commands: deps install, pre-migration suite run, migration task run, and post-migration suite run.
- Removed `Cerberus.MigrationVerification` runtime helper from `lib/cerberus/migration_verification.ex`; it is no longer needed for production code paths.
- Kept the migration verification scope as the migration-ready fixture pattern `test/features/pt_*_test.exs`, and made command-level exit status (`0`) the assertion source of truth.
- Updated migration docs to remove helper/report references and describe the direct command-based verification flow.
- Updated matrix docs to reflect CI now asserting successful pre/post full-pattern runs rather than row-level report output.
- Verified with `mix test test/cerberus/migration_verification_test.exs` and `mix precommit`.
