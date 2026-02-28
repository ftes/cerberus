---
# cerberus-ld1x
title: Switch test stack from SQLite to Postgres
status: completed
type: task
priority: normal
created_at: 2026-02-28T18:17:20Z
updated_at: 2026-02-28T19:11:37Z
---

Replace SQLite test repo config/adapter with Postgres, update deps and CI docs/workflow so local and CI tests run against Postgres by default.

## Summary of Changes

- Switched test DB adapter from SQLite to Postgres by replacing `ecto_sqlite3` with `postgrex` in `mix.exs` and pruning unused lock entries.
- Updated fixture repo adapter to `Ecto.Adapters.Postgres`.
- Reworked `config/test.exs` to Phoenix-style Postgres settings using standard env vars (`POSTGRES_*`) with process-unique default database naming (`cerberus_test_<pid>`).
- Reworked `test/test_helper.exs` bootstrap to:
  - ensure the configured Postgres test database exists,
  - tolerate concurrent create races (`duplicate_database`),
  - initialize/truncate `sandbox_messages` with Postgres SQL under an advisory lock for startup safety.
- Updated CI workflow to run with a Postgres 16 service and Postgres env defaults.
- Added README maintainer note for local Postgres test setup and default envs.

## Verification

- `POSTGRES_HOST=127.0.0.1 POSTGRES_PORT=5432 POSTGRES_USER=postgres POSTGRES_PASSWORD=postgres mix test test/core/static_upload_behavior_test.exs`
- `POSTGRES_HOST=127.0.0.1 POSTGRES_PORT=5432 POSTGRES_USER=postgres POSTGRES_PASSWORD=postgres mix test test/cerberus/migration_verification_test.exs:148`
