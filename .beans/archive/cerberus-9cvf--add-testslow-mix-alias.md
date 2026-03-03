---
# cerberus-9cvf
title: Add test.slow mix alias
status: completed
type: task
priority: normal
created_at: 2026-03-03T15:27:46Z
updated_at: 2026-03-03T15:35:12Z
---

Add a discoverable mix alias for running slow-tagged tests and ensure it runs in the test environment.

## Summary of Changes
- Added a discoverable `mix test.slow` alias in `mix.exs`.
- Restored `test: :test` in `preferred_envs` so `mix test` runs in test env and resolves `ecto.*` tasks.
- Implemented `test.slow` as `cmd env MIX_ENV=test mix test --only slow` for deterministic test env behavior with dotted alias names.
- Verified with `mix test test/cerberus/locator_parity_test.exs` (excluded by default) and `mix test.slow test/cerberus/locator_parity_test.exs` (runs and passes).
