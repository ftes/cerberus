---
# cerberus-qcft
title: 'Migrate next EV2 slice: notifications and my_timecards browser tests'
status: in-progress
type: task
created_at: 2026-03-07T05:21:30Z
updated_at: 2026-03-07T05:21:30Z
---

## Scope\n\n- [ ] Migrate a clean non-browser slice in test/ev2_web/live/project_settings_live/notifications_test.exs from PhoenixTest to Cerberus using ConnCase.\n- [ ] Migrate a browser slice in test/features/my_timecards_browser_test.exs from Playwright to Cerberus using UI login and browser sandbox metadata.\n- [ ] Keep structured locators during migration and tag migrated coverage with :cerbrerus.\n- [ ] Run targeted MIX_ENV=test test commands with random PORT values and record results.\n\n## Notes\n\nConsult MIGRATE_FROM_PHOENIX_TEST.md first and keep the remaining known browser parity gaps out of scope for this slice.
