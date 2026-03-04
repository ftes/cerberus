---
# cerberus-e1zp
title: Investigate cross_driver_text regression
status: completed
type: bug
priority: normal
created_at: 2026-03-04T09:37:55Z
updated_at: 2026-03-04T09:39:55Z
---

Investigate potential regression around test/cerberus/cross_driver_text_test.exs:12 after recent render_html commit and verify/fix if needed.

## Todo
- [x] Reproduce failure in test/cerberus/cross_driver_text_test.exs with random PORT
- [x] Trace root cause to recent changes or unrelated in-progress edits
- [x] Implement fix if needed and run targeted tests
- [x] Add summary and complete bean

## Summary of Changes
- Reproduced failure in  with  and confirmed  in  for regex locator input.
- Root cause:  guard  excluded  structs, so  and  no longer matched function clauses.
- Fixed by adding  +  guard that accepts string/regex shorthand specifically for assertion APIs, while keeping other locator guards unchanged.
- Ran  and verified with Running ExUnit with seed: 707330, max_cases: 28
Excluding tags: [slow: true]

....
Finished in 3.1 seconds (3.1s async, 0.00s sync)
4 tests, 0 failures (4 tests, 0 failures).

## Corrected Summary of Changes
- Reproduced failure at test/cerberus/cross_driver_text_test.exs line 12 with PORT=4127 and confirmed a FunctionClauseError in Cerberus.Assertions.assert_has/3 for regex locator input.
- Root cause: guard is_locator_input/1 in lib/cerberus/assertions.ex excluded Regex structs, so assert_has with regex and refute_has with regex no longer matched clauses.
- Fixed by adding assert_locator_input and is_assert_locator_input/1, then using that guard for assert_has/3 and refute_has/3.
- Ran mix format for lib/cerberus/assertions.ex and verified with source .envrc and PORT=4286 mix test test/cerberus/cross_driver_text_test.exs, which now passes with 4 tests and 0 failures.
