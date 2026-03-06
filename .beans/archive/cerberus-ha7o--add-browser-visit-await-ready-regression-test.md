---
# cerberus-ha7o
title: Add browser visit await_ready regression test
status: completed
type: task
priority: normal
created_at: 2026-03-06T19:32:59Z
updated_at: 2026-03-06T19:45:41Z
---

Add a Cerberus browser test that captures missing readiness wait on visit/3 for LiveView routes, and run targeted test with MIX_ENV=test and random PORT.

## TODO
- [x] Inspect browser visit settle path and identify missing readiness call
- [x] Implement await_ready behavior on successful browser visit for LiveView routes
- [x] Run targeted browser settle tests with MIX_ENV=test and random PORT
- [x] Update bean summary and mark completed

## Summary of Changes
- Added browser regression test browser visit on live routes performs await_ready in test/cerberus/browser_action_settle_behavior_test.exs.
- Updated browser visit flow in lib/cerberus/driver/browser.ex to call await_driver_ready after successful navigate before snapshot capture.
- Visit observed metadata now includes readiness payload, matching click and submit settle behavior.
- Kept interrupted-navigation visit path aligned by carrying readiness through await and snapshot handling.
- Verified with targeted run: source .envrc and PORT=4721 MIX_ENV=test mix test test/cerberus/browser_action_settle_behavior_test.exs test/cerberus/sql_sandbox_behavior_test.exs, resulting in 9 tests and 0 failures.
