# Migration Verification Loop

This guide documents the current migration verification loop for PhoenixTest-to-Cerberus rewrites.

## Goal

Provide deterministic confidence that selected PhoenixTest scenarios still pass after running:

1. pre-migration test run (`PhoenixTest` mode)
2. `mix igniter.cerberus.migrate_phoenix_test --write` rewrite
3. post-migration test run (`Cerberus` mode)

## How To Run

Run the verification suite:

```bash
mix test test/cerberus/migration_verification_test.exs
```

The suite uses the internal migration verification helper and runs against the committed fixture project at:

- `fixtures/migration_project`

## What Is Reported

The verification helper returns row-level parity output:

- `report.rows`: one row per scenario
  - `id`
  - `test_file`
  - `pre_status` (`:pass | :fail | :not_run`)
  - `post_status` (`:pass | :fail | :not_run`)
  - `parity` (`true | false`)
- `report.summary`:
  - `total_rows`
  - `pre_pass_rows`
  - `post_pass_rows`
  - `parity_pass_rows`
  - `all_parity_pass?`

When a stage fails, the error payload includes:

- failure stage (`:prepare | :deps_get | :pre_test | :migrate | :post_test`)
- failing `row_id` and `test_file`
- partial `report` state up to the failure point

## CI Integration

The CI smoke job runs this suite:

- `.github/workflows/ci.yml` → `Smoke (non-browser)` → `Run migration verification tests`

This keeps migration verification in non-browser CI by default and avoids browser runtime overhead in precommit/smoke lanes.

## Intentional Boundaries

Current loop scope is intentionally narrow:

- Non-browser migration scenario rows are the current source of truth.
- Matrix breadth in `docs/migration-verification-matrix.md` is a roadmap, not fully implemented row coverage yet.
- Browser-specific PhoenixTest.Playwright parity rows are still pending broader migration support and runtime-cost decisions.
- The Igniter task remains a safe-rewrite tool; unsupported patterns are warnings and require manual migration follow-up.

## Extending Coverage

To add a new row:

1. Add/extend a fixture test under `fixtures/migration_project/test/features`.
2. Add a row entry to the verification helper options in tests (or default rows when stable).
3. Assert parity outcomes in `test/cerberus/migration_verification_test.exs`.
4. Update `docs/migration-verification-matrix.md` to keep the matrix and implemented rows aligned.
