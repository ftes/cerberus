---
# cerberus-xuso
title: Fix remaining Firefox process leaks after test runs
status: completed
type: bug
priority: normal
created_at: 2026-03-12T17:01:49Z
updated_at: 2026-03-12T17:07:52Z
---

Reproduce and fix the remaining orphaned Firefox processes after Cerberus-backed EV2/Firefox runs. Validate the fix in Cerberus first, then re-check from EV2.

- [x] inspect current Firefox runtime teardown and leak window
- [x] reproduce the orphaned Firefox process behavior with focused runs
- [x] implement the smallest cleanup fix in Cerberus runtime
- [x] verify no orphaned Firefox processes remain after focused runs
- [x] note the separate slow register_and_accept_offer_cerberus_test follow-up

## Summary of Changes

- Moved Firefox watchdog marker removal to the end of managed service shutdown so the watchdog stays armed while teardown is in progress.
- Added runtime integration coverage for interrupted shutdown using an external `mix run` process that starts Firefox, begins shutdown, and halts the VM before cleanup can finish.
- Verified Cerberus runtime integration tests pass.
- Verified two fresh EV2 Firefox browser runs leave no Firefox processes behind after exit: `generate_timecards_browser_cerberus_test.exs` and `create_offer_cerberus_test.exs`.
- Noted a separate follow-up for the extremely slow `test/features/register_and_accept_offer_cerberus_test.exs`.
