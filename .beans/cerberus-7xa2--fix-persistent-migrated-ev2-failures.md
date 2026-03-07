---
# cerberus-7xa2
title: Fix persistent migrated EV2 failures
status: completed
type: task
priority: normal
created_at: 2026-03-07T07:20:57Z
updated_at: 2026-03-07T07:26:26Z
---

## Scope

- [x] Inspect persistent migrated EV2 failures in notifications and preferences.
- [x] Fix the migrated tests or helpers with the least invasive change.
- [x] Re-run the persistent failing files with random PORT values.
- [x] Re-run the full migrated EV2 Cerberus suite to confirm the fixes.

## Summary of Changes

Updated /Users/ftes/src/ev2-copy/test/ev2_web/live/user_live/preferences_form_test.exs to target the real Quill editor surface instead of the hidden signature input. The migrated browser test now mirrors the old Playwright interaction and persistence check.

Updated /Users/ftes/src/ev2-copy/test/ev2_web/live/project_settings_live/notifications_test.exs to give the operating-base row assertion a slightly larger timeout under live rendering pressure.

Targeted verification:
- PORT=4862 MIX_ENV=test mix test test/ev2_web/live/project_settings_live/notifications_test.exs test/ev2_web/live/user_live/preferences_form_test.exs --include integration
  - 19 tests, 0 failures

Full migrated suite rerun:
- PORT=4897 MIX_ENV=test mix test --only cerbrerus --include integration
  - 275 tests, 5 failures, 6 skipped

The original persistent failures are fixed. The remaining 5 failures are a different set of live-side failures under full-suite load, including:
- /Users/ftes/src/ev2-copy/test/ev2_web/live/project_live/show_test.exs:177
- /Users/ftes/src/ev2-copy/test/ev2_web/live/project_settings_live/notifications_test.exs:25
- /Users/ftes/src/ev2-copy/test/ev2_web/live/project_settings_live/dates_test.exs:17
- /Users/ftes/src/ev2-copy/test/ev2_web/live/project_settings_live/dates_test.exs:27
- one additional failure in the same full run that was not captured in the streamed output before completion

A DBConnection.OwnershipError also appeared during the full run in a nested LiveView mount on /projects/911/timecards/... while the suite continued, which suggests there is still broader sandbox/live concurrency instability in the migrated set beyond the two tests fixed here.
