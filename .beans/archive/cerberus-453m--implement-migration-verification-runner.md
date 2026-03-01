---
# cerberus-453m
title: Implement migration verification runner
status: completed
type: task
priority: normal
created_at: 2026-02-28T08:47:02Z
updated_at: 2026-02-28T13:52:45Z
parent: cerberus-it5x
---

Add automation that executes fixture tests pre-migration, runs Igniter migration, then executes rewritten Cerberus tests post-migration.

## Summary of Changes
- Added Cerberus.MigrationVerification orchestration module for pre-migration run, rewrite, and post-migration run.
- Added ExUnit coverage in test/cerberus/migration_verification_test.exs for orchestration order and failure reporting.
- Moved migration fixture project from test/support/fixtures/migration_project to fixtures/migration_project so regular test compilation does not include fixture sources.
- Updated migration task tests and defaults to use fixtures/migration_project.
- Removed the custom mix task entrypoint and switched docs to the ExUnit test entrypoint.
