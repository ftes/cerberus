---
# cerberus-1xnx
title: Expand locator oracle corpus with tricky cases
status: completed
type: task
priority: normal
created_at: 2026-03-01T16:06:36Z
updated_at: 2026-03-01T16:11:21Z
---

Build an extensive snippet-based locator oracle test corpus with many short/tricky examples and parity checks between static (Elixir) and browser (JS) matching.

## Todo
- [x] Refactor locator oracle harness to support per-case snippets and richer case definitions
- [x] Add a broad corpus of tricky locator cases (text/regex/exact/ws/visibility/role/label/css/testid/errors/disambiguation)
- [x] Run focused locator oracle tests and precommit
- [x] Mark other locator-engine beans with oracle-corpus prerequisite
- [x] Summarize and complete bean

## Summary of Changes
- Reworked `test/cerberus/core/locator_oracle_harness_test.exs` into a corpus-driven parity harness with per-case HTML snippets and per-case operations.
- Added a broad tricky-case corpus across assertions and form actions, including visibility behavior, helper mappings, unsupported locators/options, sigil variants, selector disambiguation, and invalid-locator failures.
- Fixed harness compile-time module attribute usage by replacing runtime `wrap/1` calls with compile-time HTML prefix/suffix attributes.
- Validated with focused suite: `mix test --warnings-as-errors test/cerberus/core/locator_oracle_harness_test.exs` and `mix precommit`.
- Marked follow-up locator beans (`cerberus-d2lg`, `cerberus-copd`, `cerberus-ke49`, `cerberus-bgq4`) as blocked by this corpus work and added explicit prerequisite notes.
