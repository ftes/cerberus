---
# cerberus-t7yo
title: Explain Locator.input breadth and map/keyword support
status: completed
type: task
priority: normal
created_at: 2026-03-06T10:31:14Z
updated_at: 2026-03-06T10:32:38Z
---

## Goal
Explain why Locator.input() includes maps/keywords instead of only Locator.t(), and whether narrowing is feasible.

## Todo
- [x] Inspect Locator.input() typespec and normalize paths
- [x] Check public API docs/usages that rely on map/keyword inputs
- [x] Provide recommendation with tradeoffs

## Summary of Changes
- Confirmed Locator.input is intentionally broad (t | keyword | map | nested list) and normalize! accepts keyword/map literal locators.
- Confirmed current tests/docs still use keyword locator literals (for example click(text: ...), assert_has(text: ...), submit(text: ...)).
- Confirmed map input supports atom and string keys during normalization and is exercised by map-composition tests.
