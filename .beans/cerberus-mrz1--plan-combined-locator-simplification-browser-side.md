---
# cerberus-mrz1
title: Plan combined locator simplification + browser-side action resolution
status: completed
type: task
priority: normal
created_at: 2026-03-03T08:31:03Z
updated_at: 2026-03-03T08:31:27Z
---

Create implementation plan to simultaneously move browser action ops to in-browser locator resolution/waiting and simplify API by passing locators unchanged to drivers, including synergies and sequencing.

## Summary of Changes
Produced integrated migration plan: implement browser-side Playwright-style action resolution/wait loops and locator pass-through simplification together in operation slices. Identified core synergies (single source of locator semantics, fewer roundtrips, easier backend swap) and sequencing to limit blast radius across browser/live/static drivers and tests.
