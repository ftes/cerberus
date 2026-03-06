---
# cerberus-7b3a
title: Switch locator piping to scope semantics and add filter
status: completed
type: feature
priority: normal
created_at: 2026-03-06T09:30:07Z
updated_at: 2026-03-06T10:00:46Z
---

## Goal\n\nClean-cut API migration to Playwright-like locator semantics:\n- Piped locator composition means scope (descendant), not same-element intersection.\n- Add filter/2 with has and has_not options.\n- Remove top-level has/2 and has_not/2 APIs and legacy selector options for locator actions.\n- Keep within/3 as sugar and iframe scope support.\n\n## Todo\n\n- [x] Update locator AST/normalization to represent scope chaining and filter options\n- [x] Update public Cerberus API to remove has/has_not and selector options, add filter/2\n- [x] Update static/live/browser resolvers to new semantics and remove selector-option paths\n- [x] Update tests/docs for clean-cut behavior\n- [x] Run format and targeted tests (with sourced env + random PORT)\n

## Summary of Changes

- Switched piped locator composition to scope semantics by introducing scope composite normalization and composition, and wiring helper overloads such as text/2 and label/2 through scope/2.
- Added public filter/2 with has and has_not options, and removed public has/2 and has_not/2 helpers.
- Removed public selector options from locator/action APIs and browser type/press options; changed Browser.type/4 and Browser.press/4 to take locator as a top-level argument.
- Updated browser, static, live, HTML, and LiveView locator resolvers to handle scope locators and removed selector-option dependency paths used by public APIs.
- Updated docs and tests for clean-cut behavior (and_ for same-element intersection, filter for nested constraints, scope-chain examples), then ran format and targeted tests with sourced env and random ports.

Targeted test runs:
- source .envrc && PORT=4127 mix test test/cerberus/locator_test.exs test/cerberus/within_closest_behavior_test.exs test/cerberus/helper_locator_behavior_test.exs test/cerberus/browser_extensions_test.exs test/cerberus/documentation_examples_test.exs
- source .envrc && PORT=4128 mix test test/cerberus/locator_parity_test.exs --include slow

## Summary of Changes

- Switched piped locator composition to scope semantics by introducing  composite normalization/composition and wiring helper overloads (, , etc.) through .
- Added public  with  and  options, and removed public  and  helpers.
- Removed public selector options from locator/action APIs and browser type/press options; changed  and  to take locator as a top-level argument.
- Updated browser/static/live and HTML/LiveView locator resolvers to handle scope locators and removed selector-option dependency paths used by public APIs.
- Updated docs and tests for clean-cut behavior ( for same-element intersection,  for nested constraints, scope-chain examples), then ran format and targeted tests with sourced env and random ports.

Targeted test runs:
- Running ExUnit with seed: 279372, max_cases: 28
Excluding tags: [slow: true]

....................................................................................................................................
Finished in 39.5 seconds (39.5s async, 0.00s sync)
132 tests, 0 failures
- Running ExUnit with seed: 601844, max_cases: 28
Including tags: [:slow]

..
Finished in 29.1 seconds (0.00s async, 29.1s sync)
2 tests, 0 failures
