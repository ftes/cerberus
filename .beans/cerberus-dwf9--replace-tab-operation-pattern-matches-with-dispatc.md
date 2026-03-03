---
# cerberus-dwf9
title: Replace tab operation pattern matches with dispatch helper
status: todo
type: task
priority: normal
created_at: 2026-03-03T19:54:20Z
updated_at: 2026-03-03T19:54:28Z
parent: cerberus-5xxo
---

## Goal
Replace top-level pattern-matched tab operation routing with centralized dispatch helper/protocol usage.

## Todo
- [ ] Introduce tab dispatch helper
- [ ] Update open_tab/close_tab/switch_tab to delegate through helper
- [ ] Preserve endpoint guard semantics for non-browser switching
- [ ] Run format + targeted tab tests
