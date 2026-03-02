---
# cerberus-3rtd
title: Improve migration rewrites to canonical call forms
status: completed
type: task
priority: normal
created_at: 2026-03-02T12:55:10Z
updated_at: 2026-03-02T13:27:52Z
---

Extend the PhoenixTest migration rewrites to prefer canonical Cerberus call forms with positional binary shorthand where applicable. Convert assert_has and refute_has text keyword args to positional binary locator args, and convert fill_in style keyword usage with label and with keys to positional label and value args. Include equivalent normalization for other label-first form helpers where safe. Add migration task tests and fixture matrix rows that prove canonical rewrites preserve behavior.

## Progress
- Switched `mix cerberus.migrate_phoenix_test` implementation to `use Igniter.Mix.Task` and route file updates through `Igniter.update_file/4` (write mode).
- Kept legacy dry-run/write semantics (`--write` applies, default dry-run) and existing summary/warning output format.
- Added `igniter` as a direct dependency in `mix.exs` so the task compiles when Cerberus is consumed as a dependency in migration fixtures.
- Verified migration task test suite passes after switch.
- Canonical argument-shape rewrites (assert_has/fill_in shorthand normalization) still pending.

## Summary of Changes
- Migrated `mix cerberus.migrate_phoenix_test` to an Igniter task (`use Igniter.Mix.Task`) while preserving existing CLI behavior (default dry-run, `--write` applies updates, legacy warning/summary output).
- Added `igniter` as a direct dependency and lockfile entries so the migration task compiles both in this repo and when Cerberus is used as a dependency in fixture migration projects.
- Kept dry-run output using explicit git-style diff rendering and switched write-mode file application through `Igniter.update_file/4`.
- Added a canonical argument-shape pass after base AST rewrites:
  - `assert_has/refute_has(..., text: value)` => positional text argument
  - `fill_in(..., with: value)` => positional value argument
  - `select(..., option: value)` => positional option argument
  - supports both remote calls (`Cerberus.fill_in(...)`) and piped local-call forms (`|> fill_in(...)`).
- Expanded migration task tests to assert canonical output for direct calls, alias-based calls, local import/pipeline forms, and fixture-project migration rows.
- Validation:
  - `mix test --no-compile test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs` passes (`14 tests, 0 failures`).
  - Dry-run sample now shows canonical form, e.g. `Cerberus.fill_in(session, "Search term", value)` and `Cerberus.assert_has(session, "body", expected)`.
