---
# cerberus-dwf9
title: Replace tab operation pattern matches with dispatch helper
status: completed
type: task
priority: normal
created_at: 2026-03-03T19:54:20Z
updated_at: 2026-03-03T20:13:39Z
parent: cerberus-5xxo
---

## Goal
Replace top-level pattern-matched tab operation routing with centralized dispatch helper/protocol usage.

## Todo
- [x] Introduce tab dispatch helper
- [x] Update open_tab/close_tab/switch_tab to delegate through helper
- [x] Preserve endpoint guard semantics for non-browser switching
- [x] Run format + targeted tab tests

## Summary of Changes
- Added tab operation callbacks (open_tab/switch_tab/close_tab) to Cerberus.Driver.
- Simplified Cerberus tab APIs to use one dispatcher helper instead of per-driver pattern matches.
- Moved switch_tab guards into drivers, preserving endpoint checks for static/live and mixed browser guard errors.
- Validation: mix format, targeted tab suites (with browser), and mix precommit.
