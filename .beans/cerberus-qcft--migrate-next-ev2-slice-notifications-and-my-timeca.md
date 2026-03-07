---
# cerberus-qcft
title: 'Migrate next EV2 slice: notifications and my_timecards browser tests'
status: completed
type: task
priority: normal
created_at: 2026-03-07T05:21:30Z
updated_at: 2026-03-07T05:49:58Z
---

## Scope

- [x] Migrate a clean non-browser slice in test/ev2_web/live/project_settings_live/notifications_test.exs from PhoenixTest to Cerberus using ConnCase.
- [x] Migrate a browser slice in test/features/my_timecards_browser_test.exs from Playwright to Cerberus using UI login and browser sandbox metadata.
- [x] Keep structured locators during migration and tag migrated coverage with :cerbrerus.
- [x] Run targeted MIX_ENV=test test commands with random PORT values and record results.

## Notes

Consult MIGRATE_FROM_PHOENIX_TEST.md first and keep the remaining known browser parity gaps out of scope for this slice.

## Summary of Changes

- Migrated test/ev2_web/live/project_settings_live/notifications_test.exs to ConnCase + Cerberus and verified it passes.
- Migrated test/features/my_timecards_browser_test.exs to ConnCase + Cerberus browser sessions with UI login and sandbox user agent metadata.
- The apparent browser blocker turned out not to be a Cerberus bug. The old timecard form uses timecard_data_* control ids, so the migrated browser assertions needed to target #timecard_data_working_day_type, #timecard_data_meal_mins, #timecard_data_travel_mins, and #timecard_data_type rather than timecard_* ids or inferred label assumptions.
- Verified the slice with targeted MIX_ENV=test runs in ../ev2-copy.

## Verification

- PORT=4896 MIX_ENV=test mix test test/ev2_web/live/project_settings_live/notifications_test.exs
- PORT=4912 MIX_ENV=test mix test test/features/my_timecards_browser_test.exs --include integration
- PORT=4924 MIX_ENV=test mix test test/ev2_web/live/project_settings_live/notifications_test.exs test/features/my_timecards_browser_test.exs --include integration
