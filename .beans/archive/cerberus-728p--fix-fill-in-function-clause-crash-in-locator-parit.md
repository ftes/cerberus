---
# cerberus-728p
title: Fix fill_in function clause crash in locator parity corpus
status: completed
type: bug
priority: normal
created_at: 2026-03-04T12:18:25Z
updated_at: 2026-03-04T12:20:58Z
---

Locator parity test crashes with FunctionClauseError in Cerberus.Assertions.fill_in/4 after API cleanup.\n\n- [x] Reproduce and inspect failing call path\n- [x] Patch fill_in API guards/clauses to accept expected locator inputs\n- [x] Run focused failing test module\n- [x] Add summary and mark completed

## Summary of Changes
- Root cause: locator parity corpus still had a legacy bare regex fill_in shorthand (`fill_in(session, ~r/.../, ...)`) while API/docs now require explicit locator wrappers.
- Fixed the failing corpus row by switching to supported explicit locator form: `fill_in(session, text(~r/.../), ...)`.
- Validation: `source .envrc && PORT=4012 mix test test/cerberus/locator_parity_test.exs --include slow` -> 1 test, 0 failures.
