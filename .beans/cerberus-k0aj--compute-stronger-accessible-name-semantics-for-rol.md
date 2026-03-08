---
# cerberus-k0aj
title: Compute stronger accessible-name semantics for role locators
status: todo
type: feature
created_at: 2026-03-08T08:50:46Z
updated_at: 2026-03-08T08:50:46Z
parent: cerberus-iyju
---

## Context

Current role name matching uses a simple union of visible text, aria-label, and aria-labelledby. That is enough for the last API cut, but it is weaker than the accessible-name model Playwright relies on for getByRole name matching.

## Scope

Tighten role name matching for the currently supported role set without attempting a full WAI-ARIA implementation in one pass.

## Work

- [ ] Audit current role-name matching paths in browser, static HTML, and LiveView helpers
- [ ] Define one bounded accessible-name algorithm with explicit precedence and fallback rules
- [ ] Account for hidden-reference behavior when aria-labelledby points at hidden nodes or mixed hidden and visible nodes
- [ ] Handle aria-labelledby resolution more strictly, including multiple ids and missing references
- [ ] Evaluate the next native naming sources and role-specific naming quirks needed beyond visible text, aria-label, and aria-labelledby
- [ ] Distinguish visible text fallback from explicit naming attributes where role semantics require it
- [ ] Share the algorithm across drivers instead of re-encoding per driver
- [ ] Add targeted fixtures for buttons, links, headings, and images with competing naming sources
- [ ] Run focused parity tests plus full locator-related suites

## Notes

Examples to cover include visible text combined with aria-label, aria-labelledby pointing at multiple nodes, hidden labelled-by references, and heading or link nodes whose computed name differs from raw text.
