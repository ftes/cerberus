---
# cerberus-5uis
title: Adopt standard Phoenix test DB bootstrap
status: completed
type: task
priority: normal
created_at: 2026-03-03T15:23:59Z
updated_at: 2026-03-03T15:28:45Z
---

Goal: simplify Cerberus internal test setup using standard Phoenix/Ecto test patterns and remove unnecessary custom DB bootstrap logic where possible.

## Tasks
- [x] Audit current DB/bootstrap flow in config/test.exs, test_helper, bootstrap module, and migrations
- [x] Replace custom DB creation/reset logic with standard Ecto patterns
- [x] Keep browser/runtime setup minimal and reusable for downstream users
- [x] Run format + focused tests and document changes in bean summary

## Summary of Changes
- Removed custom Postgrex database provisioning and ad-hoc SQL table bootstrap from test setup.
- Switched to standard Ecto test setup flow: `mix test` now runs `ecto.create --quiet` and `ecto.migrate --quiet` before tests.
- Added a real migration for `sandbox_messages` at `priv/repo/migrations/20260303152500_create_sandbox_messages.exs` (using `create_if_not_exists`).
- Simplified `test/test_helper.exs` to normal supervision + SQL sandbox + endpoint startup/teardown only.
- Simplified `config/test.exs` by removing maintenance DB plumbing and setting `:base_url` directly from test config.
- Verified with `mix format` and focused tests, including browser-backed and SQL sandbox suites.
