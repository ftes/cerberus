---
# cerberus-10sq
title: Enforce has/has_not only via filter
status: completed
type: task
priority: normal
created_at: 2026-03-06T10:36:25Z
updated_at: 2026-03-06T10:42:21Z
---

## Goal
Make a clean API cut: has/has_not accepted only in filter/2, rejected everywhere else.

## Todo
- [x] Audit locator/options normalization and constructors for direct has/has_not acceptance
- [x] Remove direct has/has_not support outside filter/2
- [x] Update tests/docs for strict behavior
- [x] Run targeted tests with source .envrc and random PORT

## Summary of Changes
- Removed direct `has`/`has_not` acceptance from public locator map/keyword constructor forms (`text`, `label`, `placeholder`, `title`, `alt`, `aria_label`, `css`, `testid`, `role`).
- Kept `has`/`has_not` support in normalized locator AST so locators produced by `filter/2` remain valid across re-normalization.
- Updated `Locator.role/2` construction path to pass option keys through normalization, so unsupported keys (including `has`/`has_not`) are rejected instead of silently ignored.
- Tightened locator option types in `Cerberus.Options` so leaf/role constructor opts no longer advertise `has`/`has_not`.
- Reworked `locator_test` coverage to assert rejection outside `filter/2`, plus positive coverage for `filter(has: ...)` / `filter(has_not: ...)` including nested filters.
- Validation runs:
  - `source .envrc && PORT=4191 mix test test/cerberus/locator_test.exs`
  - `source .envrc && PORT=4194 mix test test/cerberus/locator_parity_test.exs --include slow`
  - `source .envrc && PORT=4197 mix test test/cerberus/helper_locator_behavior_test.exs test/cerberus/within_closest_behavior_test.exs`
