---
# cerberus-cbd7
title: Make fill_in label semantics explicit (text vs label locators)
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:10:34Z
updated_at: 2026-02-27T21:13:33Z
---

## Scope
Clarify and enforce locator semantics so generic text and form-label lookup are explicit.

## Goals
- Keep label(...) as explicit by-label locator for fill_in and related form ops.
- Keep string input for fill_in as ergonomic shorthand that resolves to by-label lookup.
- Ensure non-form ops keep rejecting label locators.
- Update docs/tests to make this contract obvious.

## Done When
- [x] Existing behavior confirmed or adjusted in code.
- [x] Tests cover explicit label(...) and string shorthand equivalence for form ops.
- [x] Public docs describe the split clearly.

## Summary of Changes
- Made fill_in locator normalization explicitly label-based.
- Kept plain string/regex fill_in inputs as by-label shorthand.
- Rejected explicit text locators for fill_in to preserve text-vs-label separation.
- Updated static/live/browser fill_in driver clauses to accept label locators.
- Updated tests to use string label shorthand where [text: ...] was used for fill_in, and added a guard test for rejected text locators.
- Updated README to document the fill_in label shorthand and explicit text-locator restriction.
