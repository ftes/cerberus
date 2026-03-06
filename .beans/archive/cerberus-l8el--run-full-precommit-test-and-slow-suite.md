---
# cerberus-l8el
title: Run full precommit, test, and slow suite
status: completed
type: task
priority: normal
created_at: 2026-03-06T08:43:55Z
updated_at: 2026-03-06T08:49:30Z
---

## Goal
Run full validation per user request: precommit, test, and test.slow.

## Todo
- [x] Run mix precommit with env loaded
- [x] Run mix test with random PORT
- [x] Run mix test.slow with random PORT
- [x] Summarize results and complete bean

## Summary of Changes
Executed full validation with source .envrc and PORT=4274.

Results:
- mix precommit: passed (credo, dialyzer, docs all successful).
- mix test: passed (958 tests, 0 failures, 6 skipped, 1 excluded).
- mix test.slow: task does not exist in this branch (Mix suggested test). Ran fallback slow-inclusive suite via mix test --include slow.
- mix test --include slow: failed (959 tests, 2 failures, 6 skipped).

Failing tests in slow-inclusive run:
1. Cerberus.PhoenixTest.LiveTest "refute_has/3 with timeout timeout handles async navigates" at test/cerberus/phoenix_test/live_test.exs:1424.
   - FunctionClauseError in Cerberus.Html.locator_assertion_values/4 receiving {:error, {:live_redirect, ...}} instead of HTML/LazyHTML.
2. Cerberus.LocatorParityTest "rich snippet locator corpus stays in static/browser parity" at test/cerberus/locator_parity_test.exs:295.
   - ExUnit.TimeoutError (60000ms) during browser evaluate/action path.
