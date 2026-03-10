---
# cerberus-hj74
title: Identify next shared live/static hotspot after assertion short-circuit
status: completed
type: task
priority: normal
created_at: 2026-03-10T13:36:32Z
updated_at: 2026-03-10T13:47:18Z
---

Re-profile the preserved EV2 notifications Cerberus row after the shared LazyHTML assertion short-circuit work, identify the next exact hotspot, implement the next smallest shared optimization, and rerun focused plus full gates.

- [x] profile preserved EV2 notifications Cerberus row
- [x] identify the next exact hotspot boundary
- [x] implement the next smallest shared optimization
- [x] rerun focused suites and full gates
- [x] summarize impact and complete bean

## Notes

- After the shared LazyHTML count-first cut, the preserved EV2 notifications Cerberus row is 3.2s vs 2.4s for PhoenixTest.
- Re-profile shows the remaining shared hotspot is still form-field label resolution, but only around 4ms per lookup in the heaviest notifications case.
- Next unification target is browser locator assertions: align them with the same count-first, diagnostics-on-failure algorithm used in static/live.

## Summary of Changes
- profiled the preserved EV2 notifications Cerberus row after the shared count-first assertion work and confirmed the remaining shared hotspot was form-field label resolution, not document refresh
- removed unconditional state work from shared matching and then short-circuited shared LazyHTML assertions so success paths count first and only build diagnostics on failure
- preserved EV2 notifications comparison moved from roughly 9.8s vs 2.4s earlier in the session to about 3.2s vs 2.4s after the shared live/static work, with full Cerberus gates staying green
