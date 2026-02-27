---
# cerberus-kkwr
title: Move Cerberus.Harness and Cerberus.Fixtures into test support
status: completed
type: task
priority: normal
created_at: 2026-02-27T12:34:12Z
updated_at: 2026-02-27T12:34:53Z
parent: cerberus-syh3
---

## Scope
Keep test harness/fixture helpers test-only by moving `Cerberus.Harness` and `Cerberus.Fixtures` out of `lib/` and into test compilation paths.

## Tasks
- [x] Move `lib/cerberus/harness.ex` to `test/support/harness.ex`.
- [x] Move `lib/cerberus/fixtures.ex` to `test/support/fixtures.ex`.
- [x] Preserve module names and behavior (`Cerberus.Harness`, `Cerberus.Fixtures`).
- [x] Run tests to verify compile/runtime behavior remains intact.

## Done When
- [x] Harness and fixture helpers are no longer shipped from `lib`.
- [x] Test suite compiles and runs with both modules resolved from test support.

## Summary of Changes
Moved `Cerberus.Harness` and `Cerberus.Fixtures` from `lib/cerberus/` into `test/support/` while keeping module names unchanged. Verified with focused test runs (`test/cerberus/harness_test.exs` and `test/core/api_examples_test.exs`) that test-only compilation/runtime behavior remains intact.
