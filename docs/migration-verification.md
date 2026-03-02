# Migration Verification Loop

This guide documents the current migration verification loop for PhoenixTest-to-Cerberus rewrites.

## Goal

Provide deterministic confidence that the committed migration-ready fixture suite still passes after running:

1. pre-migration test run (`PhoenixTest` mode)
2. `mix cerberus.migrate_phoenix_test --write` rewrite
3. post-migration test run (`Cerberus` mode)

## How To Run

Run the verification suite:

```bash
mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs
```

The suite runs directly against the committed fixture project at:

- `fixtures/migration_project`

## What Is Asserted

The test performs one end-to-end flow over `test/features/pt*_test.exs`:

1. `mix deps.get`
2. pre-migration run: `mix test ...` with `CERBERUS_MIGRATION_FIXTURE_MODE=phoenix_test`
3. rewrite run: `mix cerberus.migrate_phoenix_test --write ...`
4. post-migration run: `mix test ...` with `CERBERUS_MIGRATION_FIXTURE_MODE=cerberus`

Each step must exit with status `0`.

## CI Integration

The CI job runs this suite:

- `.github/workflows/ci.yml` → `CI` → `Run non-browser tests`

This keeps migration verification in the non-browser phase by default and avoids coupling parity checks to browser-runtime setup.

## Intentional Boundaries

Current loop scope is intentionally narrow:

- `pt_*` rows are the required migration gate.
- `ptpw_*` rows are included in the suite but may skip when Playwright node assets are not installed in the fixture app.
- Matrix breadth in `docs/migration-verification-matrix.md` is a roadmap, not fully implemented row coverage yet.
- Browser-specific PhoenixTest.Playwright parity rows are still pending broader migration support and runtime-cost decisions.
- The Igniter task remains a safe-rewrite tool; unsupported patterns are warnings and require manual migration follow-up.

## Extending Coverage

To extend coverage:

1. Add/extend fixture tests under `fixtures/migration_project/test/features`.
2. Keep assertions mode-aware (`CERBERUS_MIGRATION_FIXTURE_MODE`) when PhoenixTest and Cerberus setup differs.
3. Update `docs/migration-verification-matrix.md` when adding new scenario families.
