---
# cerberus-7xfp
title: Rewrite live driver around current LazyHTML snapshots
status: in-progress
type: task
priority: normal
created_at: 2026-03-10T07:40:50Z
updated_at: 2026-03-10T09:53:00Z
---

Rework the Cerberus live driver toward a PhoenixTest-style path: resolve against the current LazyHTML snapshot, use LiveViewClient tree/html_document refresh instead of render plus parse, avoid bespoke actionability machinery unless actual Phoenix or HTML truth requires it, and broaden test coverage incrementally while keeping the implementation minimal.

## Summary of Changes

- rewrote the remaining live event success paths to refresh from the current LiveView tree instead of parsing returned HTML strings
- cleared live lookup cache on conn/session refresh so resolved live fields and buttons cannot leak across route changes
- fixed the live password auth regression after logout/login introduced by the earlier lookup-cache work
- verified focused live regressions, the preserved EV2 notifications pair, and the full Cerberus gate


## Notes

- live sessions now reuse current LazyHTML snapshots by render version instead of forcing render plus parse in hot paths
- live driver caches resolved field, submit-button, and clickable-button lookups per render version and invalidates on refresh
- live button lookup now uses the shared HTML button resolver first and enriches the matched node with LiveView-specific metadata, falling back to live-only lookup only for non-button phx-click targets
- live field enrichment is now op-aware so fill-like actions skip checkbox, radio, and option phx-click metadata they do not use
- preserved EV2 notifications Cerberus row improved to 9.8s warm, down from roughly 14s before the live-driver rewrite work
