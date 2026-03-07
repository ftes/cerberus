---
# cerberus-p32f
title: Stabilize browser action settle budget test
status: completed
type: bug
priority: normal
created_at: 2026-03-07T05:47:57Z
updated_at: 2026-03-07T05:52:04Z
---

CI flake in test/cerberus/browser_action_settle_behavior_test.exs:105

## Todo
- [x] Inspect the failing test and supporting fixture/driver code
- [x] Implement the minimal fix for the race or timing issue
- [x] Run targeted formatting and tests
- [x] Update the bean with a summary and complete it if all checks pass

## Summary of Changes
- Reduced the long-action budget fixture delays so each individual phase stays comfortably below the 3s action timeout while the combined resolve + settle duration still exceeds it.
- Added a short fixture comment explaining the intended timing margin for CI stability.
- Verified the focused test five times with random PORT values and reran the full browser settle behavior test file.
