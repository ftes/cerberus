---
# cerberus-1lsa
title: Collapse older text-assertion internals onto locator-native assertions
status: todo
type: task
created_at: 2026-03-08T08:50:46Z
updated_at: 2026-03-08T08:50:46Z
parent: cerberus-iyju
---

## Context

Several assertion paths still center on generic text collection and late filtering, especially in static, live, and browser assertion helpers. That structure is harder to reason about now that the public API is locator-first.

## Scope

Refactor the remaining older text-assertion paths so named locators, role locators, and field locators stay on locator-native execution paths end to end.

## Work

- [ ] Audit assertion entry points in browser, static, and live drivers for generic text-collection fallback paths
- [ ] Split plain text assertions from locator assertions more cleanly
- [ ] Route title, alt, placeholder, testid, label, and role assertions through dedicated locator helpers instead of generic text pipelines
- [ ] Reduce duplicated matching helpers after the routing split
- [ ] Preserve current error reporting and exact or regex semantics
- [ ] Add regression coverage around locator plus text, locator plus locator, and scoped assertion cases
