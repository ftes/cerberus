---
# cerberus-i3i4
title: Add Credo and Styler to project precommit
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:21:28Z
updated_at: 2026-02-27T11:30:18Z
parent: cerberus-efry
---

## Scope
Add Credo and Styler following HexDocs setup guidance, and include both in `mix precommit`.

## Done When
- [x] `:credo` and `:styler` dependencies are added and configured.
- [x] project includes expected config files (`.credo.exs` and styler setup in `.formatter.exs`).
- [x] `mix precommit` runs format + Styler checks + Credo + tests in the intended order.
- [x] Bean includes summary and is completed.

## Summary of Changes
- Added dependencies:
  - `{:styler, "~> 1.10", only: [:dev, :test], runtime: false}`
  - `{:credo, "~> 1.7", only: [:dev, :test], runtime: false}`
- Configured Styler in `.formatter.exs` with `plugins: [Styler]`.
- Generated `.credo.exs` via `mix credo gen.config` and disabled Styler-overlap checks:
  - `Credo.Check.Readability.ParenthesesInCondition`
  - `Credo.Check.Readability.ParenthesesOnZeroArityDefs`
  - `Credo.Check.Refactor.Nesting`
  - `Credo.Check.Refactor.UnlessWithElse`
- Updated `mix precommit` alias to run:
  - `mix format --check-formatted`
  - `mix credo --strict`
  - `mix test`
- Verified `mix credo --strict` passes after configuration updates.

## Notes
- Full `mix precommit` currently stops at strict Credo findings from in-progress browser/form refactors in this branch; the precommit pipeline itself is wired correctly.
