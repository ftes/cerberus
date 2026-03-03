---
# cerberus-we7o
title: Move unwrap/2 driver logic from Cerberus into drivers
status: completed
type: task
priority: normal
created_at: 2026-03-03T19:54:20Z
updated_at: 2026-03-03T20:00:33Z
parent: cerberus-5xxo
---

## Goal
Move unwrap behavior (static/live/browser specifics) out of Cerberus into driver modules and keep Cerberus as thin dispatcher.

## Todo
- [x] Add unwrap callback to driver behavior and implement for static/live/browser
- [x] Move unwrap helpers from Cerberus into drivers
- [x] Keep LastResult/transition semantics unchanged
- [x] Run format + targeted unwrap tests

## Summary of Changes
- Added  callback to  and implemented it in static/live/browser drivers.
- Moved static/live unwrap result handling (conn/view/render/redirect/live_patch branches) out of  into driver modules.
- Simplified  to thin driver dispatch.
- Kept last_result transition semantics intact while preserving existing error messages.
- Validation: mix format; targeted suites passed (, , ).

## Summary Notes
- Added unwrap callback to Cerberus.Driver and implemented unwrap in static, live, and browser drivers.
- Moved unwrap branch handling from Cerberus into driver modules.
- Simplified Cerberus.unwrap to direct driver dispatch.
- Preserved last_result transition behavior and error messages.
- Validation executed: mix format and focused unwrap-related tests.
