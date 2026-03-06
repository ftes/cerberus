---
# cerberus-hz8j
title: Clarify browser post-navigation readiness failures
status: completed
type: bug
priority: normal
created_at: 2026-03-06T21:17:35Z
updated_at: 2026-03-06T21:21:44Z
---

## Goal
Distinguish successful browser navigation from subsequent readiness failure in user-facing errors.

## Todo
- [x] Add a regression fixture and failing test for navigation that reaches a rendered page but times out in await_ready
- [x] Update browser visit readiness error reporting to include the reached path/phase
- [x] Run targeted tests with random PORT values
- [x] Summarize the change and any remaining gaps



## Summary of Changes

Added a busy-live-root fixture that reaches a rendered page but never settles readiness because of continuous DOM mutations. Added a browser readiness regression asserting that `visit/3` reports the reached path and identifies the failure as post-navigation readiness failure. Updated browser readiness error formatting so `visit/3` and action-driven readiness failures distinguish successful navigation from later readiness failure. Verified with targeted browser readiness and actionability tests using random PORT values.
