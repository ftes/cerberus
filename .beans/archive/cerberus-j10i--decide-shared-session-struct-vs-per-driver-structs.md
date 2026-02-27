---
# cerberus-j10i
title: Decide shared Session struct vs per-driver structs
status: completed
type: task
priority: normal
created_at: 2026-02-27T12:39:16Z
updated_at: 2026-02-27T12:43:55Z
---

Evaluate whether Cerberus should keep a shared Session struct or switch to per-driver session structs, considering PhoenixTest/PhoenixTest.Playwright reference patterns and current project architecture.

## Summary of Changes

- Reviewed Cerberus architecture and session dispatch (Session module, Driver behaviour, static/live/browser drivers, ADR-0001/0002/0004).
- Compared with upstream phoenix_test and phoenix_test_playwright source patterns.
- Recommendation: keep a shared Session envelope in Cerberus; if stronger typing is needed, introduce per-driver state structs inside driver_state instead of replacing the top-level session with per-driver structs.

\n## Revision Note (2026-02-27)\n\nSuperseded by updated product direction in cerberus-5b0k: non-browser behavior must match PhoenixTest auto static/live detection and switching semantics on first visit and subsequent interactions.
