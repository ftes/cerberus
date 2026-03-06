---
# cerberus-qxvh
title: Fix currently failing tests
status: completed
type: bug
priority: normal
created_at: 2026-03-05T20:09:14Z
updated_at: 2026-03-05T20:17:08Z
parent: cerberus-zh82
---

## Problem
User requested fixing all currently failing tests.

## Plan
1. Run full test suite with random PORT.
2. Reproduce failures with targeted files/lines.
3. Implement minimal fixes.
4. Re-run targeted and full tests until green.

## Summary of Changes
- Ran full suite with random port: source .envrc && PORT=4371 mix test.
- Fixed Html/LazyHTML mismatch causing FunctionClauseError in form-field label resolution by making field_match/2 accept enumerable LazyHTML query results:
  - lib/cerberus/html/html.ex
- Resolved select behavior expectation drift after PT parity migration:
  - Updated live multi-select repeated-call expectation in test/cerberus/select_choose_behavior_test.exs to accumulated semantics.
- Refined browser multi-select caching behavior to preserve repeated scalar selections only inside LiveView roots, while static/browser keeps replacement semantics:
  - lib/cerberus/driver/browser/action_helpers.ex
- Verified with targeted reruns:
  - PORT=4372 mix test test/cerberus/driver/html_test.exs test/cerberus/phoenix/live_view_html_test.exs test/cerberus/select_choose_behavior_test.exs
  - PORT=4373 mix test test/cerberus/select_choose_behavior_test.exs
- Final verification:
  - source .envrc && PORT=4374 mix test
  - Result: 1315 tests, 0 failures, 205 skipped (3 excluded).
