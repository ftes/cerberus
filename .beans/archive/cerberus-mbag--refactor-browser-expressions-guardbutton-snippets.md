---
# cerberus-mbag
title: Refactor browser expressions guard/button snippets (increment 6)
status: completed
type: task
priority: normal
created_at: 2026-03-02T06:49:14Z
updated_at: 2026-03-02T07:05:49Z
---

## Problem
expressions.ex still repeats guard condition and button candidate snippets.

## TODO
- [x] Extract shared guard-condition snippet helper
- [x] Extract shared button-candidates snippet helper
- [x] Apply helpers in select/checkbox/radio/button flows
- [x] Run format and targeted tests
- [x] Run precommit (attempted; blocked by concurrent Credo issue in lib/mix/tasks/cerberus.migrate_phoenix_test.ex)
- [x] Add summary of changes

## Summary of Changes
- Added shared guard_condition_snippet helper and reused it in select_set, checkbox_set, and radio_set.
- Added shared button_candidates_expression and reused it in clickables and button_click.
- Kept select_set arity and behavior intact while reducing duplicated inline guard and button snippets.
- Ran mix format and targeted browser suite (49 tests, 0 failures).
- Ran mix precommit; blocked by concurrent Credo issue in lib/mix/tasks/cerberus.migrate_phoenix_test.ex unrelated to this change.
