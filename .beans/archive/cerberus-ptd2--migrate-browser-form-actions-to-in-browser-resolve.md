---
# cerberus-ptd2
title: Migrate browser form actions to in-browser resolver
status: completed
type: task
priority: normal
created_at: 2026-03-03T08:36:58Z
updated_at: 2026-03-03T08:57:10Z
parent: cerberus-npb0
---

Implement browser-side action helper loop for fill_in/check/uncheck/choose/upload preserving current semantics and error reasons.

## Summary of Changes

- Routed browser `fill_in`, `check`, `uncheck`, `choose`, and `upload` through the new in-browser action resolver.
- Kept operation-specific validation semantics after target resolution (checkbox/radio/select type checks, disabled checks, upload checks).
- Added count/state/position filter handling in resolver payloads to align action matching with existing option semantics.
- Kept legacy snapshot fallback path for `:has` composition filters to preserve current behavior.
