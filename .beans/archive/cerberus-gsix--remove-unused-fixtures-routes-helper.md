---
# cerberus-gsix
title: Remove unused fixtures routes() helper
status: completed
type: task
priority: normal
created_at: 2026-02-27T12:40:10Z
updated_at: 2026-02-27T12:40:35Z
parent: cerberus-syh3
---

## Scope
Simplify test fixtures by removing the unused `Cerberus.Fixtures.routes/0` helper.

## Tasks
- [x] Remove `routes/0` from `test/support/fixtures.ex`.
- [x] Verify no remaining call sites reference `routes/0`.
- [x] Run focused tests to ensure no regression.

## Done When
- [x] `Cerberus.Fixtures` no longer defines `routes/0`.
- [x] Test suite compiles without missing fixture helpers.

## Summary of Changes
Removed the unused `routes/0` function from `Cerberus.Fixtures`. Confirmed there are no remaining references via ripgrep and validated with focused tests (`test/cerberus/harness_test.exs`, `test/core/cross_driver_text_test.exs`) passing.
