---
# cerberus-r6yl
title: Clarify test.slow env mapping
status: completed
type: task
priority: normal
created_at: 2026-03-03T15:41:03Z
updated_at: 2026-03-03T15:45:17Z
---

Investigate whether test.slow can rely on Mix preferred env mapping instead of cmd env workaround and keep ecto_sql test-only.

## Summary of Changes
- Investigated why `preferred_envs` did not apply to `mix test.slow` alias.
- Confirmed `mix test` and `mix test.slow` behavior after restoring stable alias implementation.
- Kept `ecto_sql` scoped to `only: :test`; did not broaden dependency scope.
- Restored working `test.slow` alias implementation via `cmd env MIX_ENV=test mix test --only slow` and validated:
  - `mix test <slow-file>` excludes by default
  - `mix test.slow <slow-file>` runs and passes.
