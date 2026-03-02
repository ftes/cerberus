---
# cerberus-ng8q
title: Remove Playwright migration scope from migration verification
status: completed
type: task
priority: normal
created_at: 2026-03-02T06:56:04Z
updated_at: 2026-03-02T06:59:46Z
parent: cerberus-it5x
---

User decision: exclude Playwright migration for now. Remove Playwright migration rows, fixture scenarios, migration-task warnings/rewrites, and migration tests so migration scope is PhoenixTest non-browser only.

## Progress Update

- Removed Playwright migration scope from migration verification matrix and guide docs.
- Removed Playwright migration fixture scenarios and baseline Playwright fixture test files.
- Removed Playwright migration task-specific warning and rewrite paths from mix cerberus.migrate_phoenix_test.
- Removed Playwright-specific migration task tests and reverted fixture migration row glob back to pt_ rows only.
- Removed temporary Cerberus Playwright case module that was introduced only for Playwright migration support.
- Verified with mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs and mix precommit.

## Summary of Changes

Migration verification scope is now explicitly PhoenixTest non-browser only. Playwright migration rows, related fixture tests, and Playwright-specific migration task behavior were removed.
