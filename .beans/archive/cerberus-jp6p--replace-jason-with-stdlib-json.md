---
# cerberus-jp6p
title: Replace Jason with stdlib JSON
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:03:51Z
updated_at: 2026-02-27T11:06:41Z
---

Migrate JSON usage from Jason to Elixir stdlib JSON module.\n\n## Todo\n- [x] Audit Jason usage and dependency references\n- [x] Replace Jason calls with stdlib JSON equivalents\n- [x] Remove Jason dependency and update lockfile\n- [x] Run validation (format/tests)

## Summary of Changes
- Replaced `Jason.decode/1` and `Jason.encode!/1` calls with stdlib `JSON.decode/1` and `JSON.encode!/1` in browser runtime/BiDi paths.
- Removed direct `{:jason, "~> 1.4"}` dependency from `mix.exs`.
- Updated lockfile with `mix deps.unlock jason`, removing the top-level `jason` package entry.
- Configured Phoenix to use stdlib JSON via `config :phoenix, :json_library, JSON`.
- Validation: `mix test` passed (23 tests, 0 failures). `mix format --check-formatted` still reports an unrelated pre-existing formatting issue in `test/core/api_examples_test.exs`; changed files pass `mix format --check-formatted` when checked explicitly.
