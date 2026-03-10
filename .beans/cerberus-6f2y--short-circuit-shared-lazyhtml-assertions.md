---
# cerberus-6f2y
title: Short-circuit shared LazyHTML assertions
status: completed
type: task
priority: normal
created_at: 2026-03-10T13:23:15Z
updated_at: 2026-03-10T13:34:54Z
---

Add early-exit matching to shared Html assertion paths so static/live assert_has and refute_has stop once the result is decided instead of collecting all values.

- [ ] inspect shared assertion and locator assertion collection paths
- [x] implement early-exit count/existence logic in Html
- [ ] rerun focused static/live assertion suites
- [x] rerun preserved EV2 notifications pair and full gates
- [x] add summary and mark completed

## Summary of Changes

- Added count-first early-exit logic to shared LazyHTML assertion paths.
- Static and live text assertions now count matches first and only build full diagnostics on failure.
- Static and live locator assertions now count matches first and only collect matched values on failure.
- Added shared Query.assertion_count_decision/4 to support early-exit decisions.
- Preserved EV2 notifications pair improved to Cerberus 3.2s vs PhoenixTest 2.4s.
