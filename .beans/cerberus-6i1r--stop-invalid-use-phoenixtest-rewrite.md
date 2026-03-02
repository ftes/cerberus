---
# cerberus-6i1r
title: Stop invalid use PhoenixTest rewrite
status: completed
type: bug
priority: normal
created_at: 2026-03-02T07:18:55Z
updated_at: 2026-03-02T07:20:06Z
parent: cerberus-it5x
---

Fix migration task to avoid rewriting use PhoenixTest to use Cerberus (Cerberus has no __using__). Emit explicit manual-migration warning and add tests.

## Progress Update

- Stopped automatic rewrite of use PhoenixTest to use Cerberus.
- Added explicit migration warning: use PhoenixTest has no direct Cerberus equivalent and needs manual migration.
- Added migration-task coverage that verifies use PhoenixTest remains unchanged and warning is emitted.
- Verified with mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs and mix precommit.

## Summary of Changes

Fixed an invalid migration rewrite that could produce uncompilable output, replacing it with explicit manual-migration guidance and regression coverage.
