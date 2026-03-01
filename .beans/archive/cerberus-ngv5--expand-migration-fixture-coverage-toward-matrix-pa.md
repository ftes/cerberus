---
# cerberus-ngv5
title: Expand migration fixture coverage toward matrix parity
status: completed
type: task
priority: normal
created_at: 2026-02-28T14:39:39Z
updated_at: 2026-02-28T14:59:11Z
parent: cerberus-it5x
---

Add additional fixture scenarios and migration rows so the verification loop exercises more of docs/migration-verification-matrix.md (starting with PhoenixTest core rows) and updates parity assertions accordingly.

## Summary of Changes

- Updated fixtures/migration_project/test/features/migration_ready_test.exs to use deterministic pre/post assertions that are compatible in both PhoenixTest and Cerberus modes.
- Added a real-system ExUnit coverage path in test/cerberus/migration_verification_test.exs that runs MigrationVerification.run/2 against the committed fixture using System.cmd/3.
- Asserted row-level parity summary and workspace cleanup with keep: false in that end-to-end test.
