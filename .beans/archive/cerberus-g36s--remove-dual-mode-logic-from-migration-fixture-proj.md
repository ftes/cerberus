---
# cerberus-g36s
title: Remove dual-mode logic from migration fixture project
status: completed
type: task
priority: normal
created_at: 2026-03-02T08:43:34Z
updated_at: 2026-03-02T08:51:10Z
---

Ensure fixtures/migration_project remains PhoenixTest-only input for migration verification.

- [x] Find all Cerberus references and mode-switching branches in fixtures/migration_project
- [x] Rewrite fixture tests/helpers to pure PhoenixTest paths
- [x] Adjust migration verification expectations/tests if needed
- [x] Run format and targeted migration tests
- [x] Add summary and complete bean

## Summary of Changes

- Removed all mode-env branching and Cerberus references from fixtures/migration_project feature tests so fixture input is PhoenixTest-only.
- Simplified fixture tests by removing session_for_mode and feature_session indirection and keeping direct PhoenixTest flows.
- Replaced PhoenixTest.submit helper usage in fixture rows with explicit PhoenixTest click_button calls so migrated output avoids invalid Cerberus.submit/1 calls.
- Updated migration rewrite task to auto-bootstrap conn-based visit flows into session(endpoint: @endpoint) during migration.
- Updated migration-task tests to match new bootstrap rewrite behavior and revised the full-suite test to validate pre-migration execution plus successful migration application.
- Verified with mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs and mix precommit.
