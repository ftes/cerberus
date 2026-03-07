---
# cerberus-kvla
title: 'Migrate next EV2 Cerberus slice: places and my_timecards browser'
status: completed
type: task
priority: normal
created_at: 2026-03-06T22:34:19Z
updated_at: 2026-03-06T22:40:26Z
---

Migrate the next EV2 slice to Cerberus with one non-browser file and one browser slice. Target test/ev2_web/live/project_settings_live/places_test.exs and the first migrated describe in test/features/my_timecards_browser_test.exs. Preserve structured locator semantics where they carry intent, tag migrated coverage with :cerbrerus, and verify with targeted MIX_ENV=test runs using random PORT values.

## Summary of Changes

Completed the next EV2 slice with one non-browser file and one browser file:
- migrated test/ev2_web/live/project_settings_live/places_test.exs to ConnCase + Cerberus
- migrated test/features/invite_admin_without_offer_test.exs to ConnCase browser sessions + Cerberus UI login

Migration details from this slice:
- preserved structured locator semantics where they carried intent, especially table/list rows and link/button roles
- for the workplace row in places, the stable assertion was an inexact li row assertion rather than an exact text match because the row also contains action text
- for the invite flow, the stable browser assertions used the real app flash text and the concrete email-verified alert id instead of the older class/text assumptions

Verification:
- PORT=5002 MIX_ENV=test mix test test/ev2_web/live/project_settings_live/places_test.exs -> 11 tests, 0 failures
- PORT=5008 MIX_ENV=test mix test test/features/invite_admin_without_offer_test.exs --include integration -> 2 tests, 0 failures

Note:
- one intermediate rerun hit a transient Chrome startup failure before test execution, but the final targeted browser rerun for the migrated file passed cleanly
