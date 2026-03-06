---
# cerberus-yfkj
title: Confirm test usage for label locators in actions
status: completed
type: task
priority: normal
created_at: 2026-03-06T10:30:14Z
updated_at: 2026-03-06T10:30:29Z
---

## Goal
Confirm whether tests pass label text via label(...) for fill_in and other action ops.

## Todo
- [x] Scan tests for fill_in/check/choose/select/upload label usage
- [x] Reply with concrete examples

## Summary of Changes
- Verified tests consistently pass label text to action operations via label("...") locators.
- Confirmed examples for fill_in/check/uncheck/choose/select/upload in current test suite.
