---
# cerberus-9cwo
title: Add locator oracle harness tests
status: completed
type: task
priority: normal
created_at: 2026-03-01T15:57:49Z
updated_at: 2026-03-01T16:00:58Z
---

Create dedicated tests that compare locator matching in Elixir parsing/matching and browser JS matching against the same HTML snippets, covering edge cases without full live/browser route flows.

## Todo
- [x] Inspect existing browser helper APIs for setting HTML snippets and extracting matches
- [x] Implement a locator oracle harness test module for static-vs-browser parity on snippets
- [x] Cover edge cases (whitespace, visibility, exact/inexact, link/button/label/css/role mappings)
- [x] Add follow-up beans for missing locator-engine improvements (role/label/placeholder/alt/title, count/position filters, chaining, state filters)
- [x] Run format and targeted tests

## Summary of Changes
- Added a dedicated snippet-based locator oracle harness test at `test/cerberus/core/locator_oracle_harness_test.exs`.
- The harness injects the same HTML snippet into a browser tab via `Browser.evaluate_js/2` and runs the same operations against a static snippet session, asserting status parity and expected outcomes.
- Covered edge cases for whitespace/regex/exact matching, visibility filters, role/label/css/testid behavior in assertions, and form/control locators for `fill_in`, `select`, `check`, `uncheck`, `choose`, and `upload`.
- Added explicit follow-up beans for missing locator-engine capabilities:
  - `cerberus-d2lg` (full locator engine expansion)
  - `cerberus-copd` (count/position filters)
  - `cerberus-ke49` (chaining/composition)
  - `cerberus-bgq4` (rich state filters)
