---
# cerberus-ekr1
title: Migrate browser select to in-browser resolver
status: completed
type: task
priority: normal
created_at: 2026-03-03T08:36:58Z
updated_at: 2026-03-03T08:57:27Z
parent: cerberus-npb0
---

Implement browser-side select resolution and option matching/waiting in browser JS including exact_option and multi-select semantics.

## Summary of Changes

- Routed browser `select` to resolver-first target matching in-browser.
- Preserved `exact_option` and existing select option-setting semantics by reusing existing `Expressions.select_set/5` flow after target resolution.
- Preserved disabled/non-select validation errors and fallback behavior.
