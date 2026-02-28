---
# cerberus-0iy4
title: Switch migration task from regex to AST rewrite/warning engine
status: completed
type: task
priority: normal
created_at: 2026-02-28T16:24:24Z
updated_at: 2026-02-28T16:26:13Z
parent: cerberus-it5x
---

Replace regex-based rewrites and unsupported-pattern detection in mix igniter.cerberus.migrate_phoenix_test with AST traversal while preserving existing migration behavior and warnings.

## Summary of Changes

- Replaced regex-based rewrite and warning detection in lib/mix/tasks/igniter.cerberus.migrate_phoenix_test.ex with an AST traversal engine using Code.string_to_quoted and Macro.prewalk.
- Preserved existing migration behavior for supported rewrites (import/use/alias updates) while moving warning detection to AST-based pattern checks.
- Kept warning semantics for Playwright calls, TestHelpers imports, PhoenixTest submodule aliases, direct PhoenixTest function calls, conn visit bootstrap patterns, and browser helper calls.
- Added/updated migration-task tests in test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs to cover AST rewrite behavior and warning output for Playwright case usage.
- Verified with mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs, mix test test/cerberus/migration_verification_test.exs, and mix precommit.
