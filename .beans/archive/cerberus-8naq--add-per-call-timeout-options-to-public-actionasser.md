---
# cerberus-8naq
title: Add per-call timeout options to public action/assert APIs
status: completed
type: feature
priority: normal
created_at: 2026-03-03T17:22:18Z
updated_at: 2026-03-03T17:36:31Z
---

## Goal
Add timeout option support across Cerberus and Cerberus.Browser public functions where waiting behavior applies (actions + assertions), and use it to speed intentional-failure browser tests.

## Todo
- [x] Map public functions and option schemas needing timeout
- [x] Implement timeout option validation + wiring through Cerberus/Cerberus.Browser and browser driver paths
- [x] Update/extend tests for timeout behavior and speed-sensitive failure cases
- [x] Run format + targeted tests

## Summary of Changes
- Added timeout support to core action option schemas/types (click, fill_in, select, choose, check, uncheck, submit, upload) and browser extension action opts (Browser.type/3, Browser.press/3, Browser.drag/4).
- Wired browser action timeout overrides through action execution and readiness waits so per-call timeouts control both action dispatch and post-action readiness, including timeout: 0 skip-wait behavior.
- Extended Browser.drag to accept options (drag/4) while keeping drag/3 convenience via default opts.
- Added and updated tests for timeout validation and applied small timeout overrides to intentional-failure browser scenarios to reduce slow-path runtime.
- Ran mix format and targeted tests for touched suites (108 tests, 0 failures).
