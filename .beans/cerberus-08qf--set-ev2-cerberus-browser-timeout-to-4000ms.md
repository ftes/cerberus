---
# cerberus-08qf
title: Set EV2 Cerberus browser timeout to 4000ms
status: completed
type: task
priority: normal
created_at: 2026-03-07T06:40:32Z
updated_at: 2026-03-07T07:03:45Z
---

## Scope

- [x] Add an EV2-only Cerberus browser timeout override of 4000ms in config/test.exs.
- [x] Confirm EV2 support helpers do not override browser timeout in a conflicting way.
- [x] Run targeted migrated Cerberus browser tests in /Users/ftes/src/ev2-copy with random PORT values.
- [x] Run one non-browser migrated EV2 test as a sanity check.

## Notes

Keep Cerberus library defaults unchanged.

## Summary of Changes

Added config :cerberus, :browser, timeout_ms: 4_000 to /Users/ftes/src/ev2-copy/config/test.exs while keeping the existing EV2 endpoint config unchanged.

Confirmed /Users/ftes/src/ev2-copy/test/support/cerberus.ex does not override timeout_ms, so browser sessions inherit the EV2 browser timeout from config.

Verification:
- PORT=5084 MIX_ENV=test mix test test/features/approve_timecards_test.exs test/features/register_and_accept_offer_test.exs test/features/invite_admin_without_offer_test.exs test/features/construction_rates_test.exs --include integration
  - 7 tests, 0 failures
- PORT=5096 MIX_ENV=test mix test test/ev2_web/live/project_settings_live/dates_test.exs
  - 2 tests, 0 failures
