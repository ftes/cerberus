---
# cerberus-ulf8
title: Align link click to DOM click semantics
status: todo
type: task
priority: normal
created_at: 2026-03-03T11:30:52Z
updated_at: 2026-03-03T11:30:52Z
parent: cerberus-dsr0
---

Change link actions to perform literal DOM click first, instead of href navigation shortcut.\n\nScope:\n- [ ] Execute link interaction through browser click semantics.\n- [ ] Preserve navigation wait behavior when click triggers navigation.\n- [ ] Keep compatibility for modifiers and target attributes where supported.\n- [ ] Add regression coverage for JS-intercepted links and prevented navigation.
