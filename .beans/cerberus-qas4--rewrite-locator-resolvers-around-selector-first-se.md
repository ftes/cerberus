---
# cerberus-qas4
title: Rewrite locator resolvers around selector-first semantics
status: in-progress
type: task
priority: normal
created_at: 2026-03-10T08:26:35Z
updated_at: 2026-03-10T09:53:00Z
---

Rewrite browser and LazyHTML locator resolution from scratch around a selector-first, narrow-resolution model guided by Playwright. Start by removing the temporary live label fast path, then rebuild static and live resolution, broaden browser coverage carefully, and enable parity tests incrementally while keeping complexity minimal.


## Notes

- rewrote shared LazyHTML form-field resolution around selector-first explicit-label, implicit-label, and attr-specific queries instead of the older generic candidate matcher
- rewrote shared link and button resolution to query narrowed selectors first and build matches directly, keeping the recursive generic matcher only where locator composition still needs it
- rewrote shared submit-button resolution to query submit-capable controls directly and derive owner-form metadata from the matched node instead of scanning forms and owner-form branches separately
- preserved EV2 live notifications row improved from roughly 14s before this rewrite series to 9.8s on the latest warm Cerberus rerun, versus 2.4s for the restored PhoenixTest baseline
- browser resolver rewrite is still pending; this slice only covered shared LazyHTML resolution used by static and live
