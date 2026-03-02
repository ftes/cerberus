---
# cerberus-1w97
title: Rewrite PhoenixTest.Assertions aliases during migration
status: completed
type: task
priority: normal
created_at: 2026-03-02T07:07:08Z
updated_at: 2026-03-02T07:17:22Z
parent: cerberus-it5x
---

Extend migration task to rewrite alias PhoenixTest.Assertions to alias Cerberus with preserved alias name, and add tests for default/explicit alias forms.

## Progress Update

- Added migration rewrite support for alias PhoenixTest.Assertions by rewriting it to alias Cerberus while preserving alias names.
  - Default alias form now becomes alias Cerberus, as: Assertions.
  - Explicit alias form keeps the caller alias (for example as: PTA).
- Expanded migration task tests to cover:
  - rewritten Assertions alias (default and explicit alias forms),
  - updated dry-run expectations for Assertions alias rewrite.
- Verified with mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs and mix precommit.

## Summary of Changes

Closed the PhoenixTest.Assertions alias migration gap so migrated files no longer retain stale alias references, with test coverage for both default and explicit aliasing.
