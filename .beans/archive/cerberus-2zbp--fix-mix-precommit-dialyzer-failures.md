---
# cerberus-2zbp
title: Fix mix precommit dialyzer failures
status: completed
type: bug
priority: normal
created_at: 2026-02-27T20:14:12Z
updated_at: 2026-02-27T20:22:06Z
---

## Scope
Resolve current mix precommit failures by fixing the active Dialyzer findings so precommit passes cleanly.

## Done When
- [x] Resolve Cerberus/Cerberus.Assertions no_return + invalid_contract findings for unsupported APIs.
- [x] Resolve browser/conn/live/static type warnings reported by Dialyzer.
- [x] Resolve Mix task warnings in lib/mix/tasks/assets.build.ex.
- [x] mix precommit passes with zero errors.

## Summary of Changes
- Updated unsupported API contracts in Cerberus and Cerberus.Assertions to align with no-return behavior and avoid Dialyzer contract drift.
- Fixed browser, conn, static, and live Dialyzer issues by tightening flow control and path/query helpers.
- Added :mix to Dialyzer PLT apps in mix.exs so Mix task callback/type info resolves cleanly.
- Updated mix assets task logging/type setup to remove Dialyzer callback/function warnings.
- Verified with mix dialyzer and mix precommit (both passing).
