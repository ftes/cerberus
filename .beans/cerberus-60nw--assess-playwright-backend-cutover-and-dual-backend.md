---
# cerberus-60nw
title: Assess Playwright backend cutover and dual-backend strategy
status: completed
type: task
priority: normal
created_at: 2026-03-03T07:58:48Z
updated_at: 2026-03-03T08:02:38Z
---

Evaluate feasibility of switching Cerberus browser backend from self-managed BiDi runtime to Playwright, and whether both can coexist behind config without API changes.

## Todo
- [x] Audit current Cerberus browser API coupling to runtime internals
- [x] Inspect PhoenixTestPlaywright backend and custom selector engine approach
- [x] Evaluate compatibility of custom locators with Playwright selectors
- [x] Propose migration strategy (config cutover + parallel backend support)

## Summary of Changes
Analyzed Cerberus browser internals, PhoenixTestPlaywright implementation, and Playwright custom selector engine constraints. Conclusion: Playwright cutover is feasible without public API changes, but not a low-effort swap. Best path is backend abstraction under existing session API, with config-based backend selection per run. Custom locator semantics should remain in Cerberus normalization/matching; custom Playwright selector engines are suitable only for narrow cases, not full semantic parity.
