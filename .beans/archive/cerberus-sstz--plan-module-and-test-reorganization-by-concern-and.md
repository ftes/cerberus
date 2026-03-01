---
# cerberus-sstz
title: Plan module and test reorganization by concern and driver
status: completed
type: task
priority: normal
created_at: 2026-03-01T17:12:18Z
updated_at: 2026-03-01T17:15:23Z
---

Create a concrete refactor plan to improve code organization.

Requirements:
- Organize modules/directories by main concern first (HTML vs Phoenix), then by driver.
- Keep driver logic separate unless there is strong reason to share.
- Use Phoenix/Phoenix LiveView organization style as inspiration.
- Tests should be per module under test (ModuleTest), not spread across differently named files.
- Naming should align with HTML spec and Phoenix conventions, with PhoenixTest/Playwright/Capybara inspiration.

## Todo
- [x] Audit current lib and test layout for concern/driver boundaries
- [x] Identify naming and module cohesion issues
- [x] Propose target namespace layout and migration sequence
- [x] Define test file/module colocation and renaming rules
- [x] Deliver phased plan with risk controls and checkpoints

## Summary of Changes
- Audited current module and test layout, including directory trees, module declarations, and module size hot spots.
- Identified key organization issues: namespace and path mismatch in phoenix directory modules, concern leakage across large driver modules, and behavior-focused core tests not mapped to module-under-test naming.
- Produced a phased refactor plan centered on concern-first namespaces (HTML vs Phoenix) and driver-specific implementations.
- Defined test colocation and naming rules so tests align with modules under test using ModuleTest naming.
- Added migration checkpoints and risk controls to keep behavior stable while reorganizing.
