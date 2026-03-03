---
# cerberus-9499
title: Assess Playwright trace compatibility for Cerberus
status: completed
type: task
priority: normal
created_at: 2026-03-03T08:13:03Z
updated_at: 2026-03-03T08:17:17Z
---

Goal: determine whether Cerberus can emit Playwright-compatible trace artifacts and what the best implementation path is.\n\nScope:\n- [x] Inspect Playwright trace archive format and schema expectations\n- [x] Inspect trace viewer loading and coupling points to Playwright actions/locators\n- [x] Identify minimal viable Cerberus trace artifact that still gives useful replay/debug value\n- [x] Recommend implementation strategy (full compatibility vs adapter vs custom viewer) with tradeoffs\n- [x] Provide phased plan for Cerberus

## Summary of Changes\n- Cloned Playwright sources into tmp/research/playwright to inspect trace internals.\n- Reviewed trace schema, loader, modernizer, resource lookup, and trace viewer UI/backend coupling points.\n- Confirmed viewer can ingest non-Playwright actions if core event shape is valid, but high-fidelity DOM snapshot support is the hardest part.\n- Documented a recommended Cerberus strategy: start with a Playwright-compatible lightweight trace profile, then add optional deeper capture in phases.
