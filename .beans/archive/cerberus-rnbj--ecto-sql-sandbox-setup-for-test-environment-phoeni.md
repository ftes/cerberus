---
# cerberus-rnbj
title: Ecto SQL sandbox setup for test environment (PhoenixTestPlaywright parity)
status: completed
type: bug
priority: normal
created_at: 2026-02-27T18:25:35Z
updated_at: 2026-02-27T18:52:04Z
---

Implement Ecto SQL Sandbox setup for test runs, aligned with PhoenixTestPlaywright patterns and official Ecto test environment guidance.

Scope:
- Configure test-time Ecto SQL sandbox ownership/checkout according to Ecto instructions.
- Integrate sandbox behavior with Cerberus browser/static/live test harnesses.
- Avoid introducing a required *Case module unless technically unavoidable.
- If a *Case module is required, provide a minimal one and document why.

Acceptance criteria:
- Browser-oriented tests can safely use DB state under sandbox isolation.
- Setup follows Ecto SQL sandbox recommendations for tests.
- Any required docs are updated to explain usage and constraints.

## Summary of Changes

- Added test-only Ecto wiring with `phoenix_ecto`, `ecto_sql`, and `ecto_sqlite3`, plus `Cerberus.Fixtures.Repo` config using `Ecto.Adapters.SQL.Sandbox`.
- Bootstrapped sandbox DB setup in `test/test_helper.exs` (Repo startup, table creation, manual sandbox mode).
- Integrated Phoenix sandbox plug and LiveView user-agent propagation in fixture endpoint (`Phoenix.Ecto.SQL.Sandbox` plug + socket `connect_info :user_agent`).
- Added fixture LiveView sandbox on-mount hook (`Cerberus.Fixtures.LiveSandbox`) calling `Phoenix.Ecto.SQL.Sandbox.allow/2`.
- Added DB-backed fixtures/routes for static and live conformance paths:
  - `/sandbox/messages`
  - `/live/sandbox/messages`
- Extended `Cerberus.Harness.run/run!` with `sandbox: true` support:
  - starts/stops SQL sandbox owner per run,
  - encodes sandbox metadata,
  - injects metadata into seeded conn `user-agent` header,
  - forwards metadata to browser session options.
- Extended browser startup to apply sandbox metadata via per-session user-agent override (`emulation.setUserAgentOverride`, with `network.setExtraHeaders` fallback).
- Added cross-driver conformance coverage in `test/core/sql_sandbox_conformance_test.exs` for static/live/browser DB visibility.
- Updated docs (`README.md`, `docs/fixtures.md`) to describe sandbox harness usage and fixture surface changes.

Validation:
- `mix test test/core/sql_sandbox_conformance_test.exs`
- `mix test test/cerberus/harness_test.exs test/core/live_link_navigation_test.exs test/core/sql_sandbox_conformance_test.exs`
- `mix precommit` (format/credo pass; dialyzer reports existing project baseline warnings)
