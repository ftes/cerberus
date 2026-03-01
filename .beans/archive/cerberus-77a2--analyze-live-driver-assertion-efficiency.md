---
# cerberus-77a2
title: Analyze live driver assertion efficiency
status: completed
type: task
priority: normal
created_at: 2026-03-01T15:32:34Z
updated_at: 2026-03-01T15:35:53Z
---

Investigate whether live-driver assertions can avoid HTML render+reparse loops and how LiveViewTest tracks virtual DOM internally.

## Todo
- [x] Inspect current live-driver assertion implementation
- [x] Inspect LiveViewTest internals for rendered state and selector APIs
- [x] Assess roundtrip/reparse costs and feasible optimization paths
- [x] Summarize recommendation

## Summary of Changes
- Inspected Cerberus live-driver assertions and confirmed the current path renders HTML with render(view), then reparses with Cerberus Html and LazyHTML on each assertion call.
- Inspected Phoenix LiveViewTest internals including ClientProxy, Diff, DOM, and TreeDOM, and confirmed it maintains rendered diff state plus a patched html tree with per-view lazy cache for selector operations.
- Verified LiveViewTest selector checks such as has_element? operate against cached tree and lazy data instead of HTML string re-render and reparse, which is the efficient model Cerberus can adopt for live assertions.
