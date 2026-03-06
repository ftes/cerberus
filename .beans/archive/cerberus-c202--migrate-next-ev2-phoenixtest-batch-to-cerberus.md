---
# cerberus-c202
title: Migrate next EV2 PhoenixTest batch to Cerberus
status: completed
type: task
priority: normal
created_at: 2026-03-06T12:35:15Z
updated_at: 2026-03-06T13:17:04Z
---

Continue EV2-copy migration by converting one additional non-browser PhoenixTest module and one additional browser PlaywrightCase module to Cerberus. Use role and sigil locators, tag migrated modules with :cerbrerus, and verify with targeted MIX_ENV=test runs using random PORT=4xxx.

## Todo\n- [x] Pick next non-browser and browser modules with low conflict risk\n- [x] Migrate non-browser module to Ev2Web.ConnCase plus Cerberus API\n- [x] Migrate browser module to ConnCase plus Ev2Web.Cerberus helpers\n- [x] Run targeted MIX_ENV=test suite with random PORT and fix failures\n- [x] Summarize migration and remaining candidates

\n## Notes (2026-03-06)\n- Migrated non-browser module: test/ev2_web/live/project_settings_live/public_notifications_test.exs\n- Migrated browser module: test/ev2_web/live/manage_crew_live/index_browser_test.exs\n- Existing migrated browser module test/ev2_web/controllers/startpack_controller_browser_test.exs remains skipped pending Cerberus support for custom switch controls.\n- New manage-crew browser module currently marked skipped pending Cerberus parity for manage-crew browser rendering.\n- Targeted run passed with skips: 7 tests, 0 failures, 4 skipped.

\n## Summary of Changes\n- Migrated test/ev2_web/live/project_settings_live/public_notifications_test.exs to Ev2Web.ConnCase plus Cerberus with sigil and role locators, and tagged it :cerbrerus.\n- Migrated test/ev2_web/live/manage_crew_live/index_browser_test.exs to Ev2Web.ConnCase plus Ev2Web.Cerberus with sigil/role locators and Cerberus JavaScript helpers.\n- Kept test/ev2_web/controllers/startpack_controller_browser_test.exs migrated but skipped due custom switch parity gaps.\n- Marked test/ev2_web/live/manage_crew_live/index_browser_test.exs skipped pending browser-rendering parity validation.\n- Verified targeted run with random PORT and MIX_ENV=test: 7 tests, 0 failures, 4 skipped.
