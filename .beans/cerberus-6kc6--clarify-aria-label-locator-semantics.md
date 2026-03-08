---
# cerberus-6kc6
title: Clarify aria-label locator semantics
status: completed
type: task
priority: normal
created_at: 2026-03-08T07:14:36Z
updated_at: 2026-03-08T07:17:16Z
---

## Context

Answer whether Cerberus needs the `a` aria-label locator modifier, and how that relates to Playwright locator matching for labels, titles, and aria-label.

## Todo

- [x] Inspect Cerberus locator docs and implementation
- [x] Verify Playwright behavior from primary sources
- [x] Answer with concrete guidance

## Summary of Changes

- Confirmed Cerberus models `label`, `title`, and `aria-label` as separate locator kinds.
- Confirmed Cerberus form matching defaults to label matching, with explicit `:title` and `:aria_label` match modes.
- Verified from Playwright docs that `getByLabel()` matches associated `<label>`, `aria-labelledby`, and `aria-label`, while `getByTitle()` matches `title` separately and role locators use accessible name.
