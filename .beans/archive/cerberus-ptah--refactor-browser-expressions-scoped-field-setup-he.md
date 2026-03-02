---
# cerberus-ptah
title: Refactor browser expressions scoped field setup helper (increment 8)
status: completed
type: task
priority: normal
created_at: 2026-03-02T07:08:01Z
updated_at: 2026-03-02T07:17:58Z
---

## Problem
expressions.ex still repeats scoped query setup plus indexed form field lookup across multiple setters.

## TODO
- [x] Extract shared scoped form-field lookup helper
- [x] Apply helper in field_set, select_set, checkbox_set, and radio_set
- [x] Run format and targeted tests
- [x] Run precommit
- [x] Add summary of changes

## Summary of Changes
- Added scoped_form_field_lookup_snippet helper that combines scoped query setup with indexed form field lookup.
- Applied this helper to field_set, select_set, checkbox_set, and radio_set.
- Kept select_set arity and behavior intact while reducing repeated setup boilerplate.
- Ran format, targeted browser tests (49 tests), and precommit successfully.
