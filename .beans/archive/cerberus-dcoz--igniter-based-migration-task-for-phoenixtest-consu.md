---
# cerberus-dcoz
title: Igniter-based migration task for PhoenixTest consumers
status: completed
type: task
priority: normal
created_at: 2026-02-27T12:26:33Z
updated_at: 2026-02-27T19:49:10Z
---

Create an Igniter-powered migration path so consumers can migrate existing PhoenixTest test modules to Cerberus with minimal manual edits.

## Proposed Scope
- [x] Add an Igniter task (e.g. `mix cerberus.migrate_phoenix_test`) that scans test files.
- [x] Rewrite core module references from `PhoenixTest` to `Cerberus` where safe.
- [x] Migrate common API calls to Cerberus equivalents and flag unsupported cases.
- [x] Add dry-run + diff output so users can preview changes.
- [x] Add integration tests covering representative PhoenixTest fixtures.
- [x] Document migration usage and caveats in guides/README.

## Summary of Changes
- Added `mix cerberus.migrate_phoenix_test` migration task for PhoenixTest test files.
- Implemented safe rewrites for import/use/alias references that can be transformed deterministically.
- Added unsupported-pattern warnings for manual migration cases (Playwright, `conn |> visit`, `visit(conn, ...)`, direct `PhoenixTest.<function>` calls, and PhoenixTest submodule aliases/test helpers).
- Added dry-run diff preview via `git diff --no-index` and write mode via `--write`.
- Added integration tests for the migration task, including:
  - synthetic fixture rewrite + warning coverage,
  - committed fixture coverage using `test/support/fixtures/migration_source/live_test.exs` and `static_test.exs`.
- Documented migration task usage and caveats in README.

## Validation
- `mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs`
- `mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs test/cerberus/public_api_test.exs`
- `mix precommit` (Credo passes; Dialyzer remains at existing baseline warnings)
