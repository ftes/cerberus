---
# cerberus-eunz
title: Reduce wall-clock waits and tag slow timing tests
status: completed
type: task
priority: normal
created_at: 2026-03-07T06:03:21Z
updated_at: 2026-03-07T06:07:09Z
---

Follow-up to stabilize timing-heavy tests.

## Todo
- [x] Reduce the long-budget fixture timing while preserving the assertion
- [x] Identify timing-heavy tests that should be tagged slow
- [x] Apply slow tags and format touched files
- [x] Run targeted tests with random PORTs
- [x] Update bean summary and complete it

## Summary of Changes
- Reduced the long-action budget fixture from 1000/2000/1000ms phases and lowered the action timeout to 1500ms, preserving the phased-budget assertion while cutting the focused test runtime to about 1.7-1.9s.
- Tagged the readiness/actionability browser settle tests that intentionally wait on readiness timeouts as :slow.
- Tagged the browser extensions tests that use deliberate sleeps or delayed popup/dialog/download events as :slow.
- Tagged the remote webdriver integration module and websocket tests with deliberate sleep-based shutdown waits as :slow.
- Verified the affected files with --include slow and random PORT values.
