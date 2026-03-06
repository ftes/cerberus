---
# cerberus-brkl
title: Fix assert_has/3 locator+locator semantics
status: completed
type: bug
priority: normal
created_at: 2026-03-04T19:13:04Z
updated_at: 2026-03-04T19:27:35Z
---

## Problem
assert_has 3-arity treated locator plus locator as scoped assertions through within, which scoped to the first match and produced incorrect behavior for cases like css a plus text.

## Goal
Make locator plus locator assertions behave as combined matchers for assertions, not implicit first-match scoping.

## Tasks
- [x] Inspect current assert_has 3-arity dispatch and docs/types
- [x] Implement semantic change in public API dispatch
- [x] Add regression tests for locator plus locator behavior
- [x] Run format and targeted tests, plus ev2 reproduction
- [x] Add summary and mark completed

## Summary of Changes
- Changed Cerberus assert_has and refute_has 3/4-arity locator plus locator overloads to combine one text locator with one match-by locator instead of routing through scoped within behavior.
- Added merge rules for match-by locators including label, link, button, placeholder, title, alt, aria_label, testid, role, and css selectors a, a[href], and button.
- Added a regression test in path_scope_behavior_test that demonstrates non-first-match semantics with button plus text.
- Extended assert options with optional match_by and pruned nil match_by before driver dispatch so existing behavior is preserved.
- Verified in cerberus test suites and in ev2 group_list_test line 61.
