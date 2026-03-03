---
# cerberus-ulf8
title: Align link click to DOM click semantics
status: completed
type: task
priority: normal
created_at: 2026-03-03T11:30:52Z
updated_at: 2026-03-03T18:47:43Z
parent: cerberus-dsr0
---

Change link actions to perform literal DOM click first, instead of href navigation shortcut.\n\nScope:\n- [x] Execute link interaction through browser click semantics.\n- [x] Preserve navigation wait behavior when click triggers navigation.\n- [x] Keep compatibility for modifiers and target attributes where supported.\n- [x] Add regression coverage for JS-intercepted links and prevented navigation.

## Summary of Changes
- Replaced legacy browser link fallback that navigated by href with actual DOM link click execution.
- Added a dedicated browser link-click expression and wired snapshot fallback to await readiness and snapshot after click.
- Added fixture coverage for preventDefault and JS-intercepted link navigation.
- Added browser regression tests validating canceled navigation and intercepted navigation destinations.
