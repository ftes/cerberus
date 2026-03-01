---
# cerberus-xdl9
title: Merge migration verification test into mix task test file
status: completed
type: task
priority: normal
created_at: 2026-03-01T07:24:24Z
updated_at: 2026-03-01T07:26:40Z
---

Move migration verification end-to-end test into test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs and remove the separate test file.

## Todo
- [x] Move migration verification test case and helpers into mix task test module
- [x] Remove standalone migration verification test file
- [x] Update docs paths/references
- [x] Run format and targeted tests
- [x] Update bean summary and complete

## Summary of Changes
- Merged the end-to-end migration verification case into `test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs`.
- Deleted standalone `test/cerberus/migration_verification_test.exs`.
- Updated docs to point migration verification execution and references to the mix-task test file.
- Ran `mix format` and then `mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs`.
- The merged file runs, but the end-to-end migration verification test currently fails at post-migration on existing `Cerberus.Driver.LiveViewHtml` unresolved references in this branch (`pt_live_*` cases).
- Ran `mix precommit` successfully.
