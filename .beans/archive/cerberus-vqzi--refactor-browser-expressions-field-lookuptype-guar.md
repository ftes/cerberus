---
# cerberus-vqzi
title: Refactor browser expressions field lookup/type guards (increment 7)
status: completed
type: task
priority: normal
created_at: 2026-03-02T07:06:24Z
updated_at: 2026-03-02T07:07:39Z
---

## Problem
expressions.ex still repeats form field lookup and type+disabled guard snippets.

## TODO
- [x] Extract shared form-field lookup snippet helper
- [x] Extract shared typed-and-enabled field guard helper
- [x] Apply helpers in field/select/checkbox/radio flows
- [x] Run format and targeted tests
- [x] Run precommit
- [x] Add summary of changes

## Summary of Changes
- Added indexed_form_field_snippet helper to centralize field collection and indexed lookup logic.
- Added typed_enabled_field_guards_snippet helper to centralize input type and disabled guard checks.
- Applied these helpers in field_set, select_set, checkbox_set, and radio_set while keeping select_set arity and behavior intact.
- Ran format, targeted browser tests (49 tests), and precommit successfully.
