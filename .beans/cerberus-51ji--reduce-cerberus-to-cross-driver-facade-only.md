---
# cerberus-51ji
title: Reduce Cerberus to cross-driver facade only
status: todo
type: task
priority: normal
created_at: 2026-03-03T19:54:20Z
updated_at: 2026-03-03T19:54:28Z
parent: cerberus-5xxo
---

## Goal
Trim Cerberus module to cross-driver façade responsibilities only.

## Todo
- [ ] Audit remaining driver-specific branches/helpers in Cerberus
- [ ] Move candidate helper logic to drivers or shared modules
- [ ] Remove now-dead top-level helpers
- [ ] Run format + targeted regression suites
