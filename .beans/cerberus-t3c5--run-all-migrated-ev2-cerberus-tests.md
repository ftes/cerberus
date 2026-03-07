---
# cerberus-t3c5
title: Run all migrated EV2 Cerberus tests
status: completed
type: task
priority: normal
created_at: 2026-03-07T07:12:56Z
updated_at: 2026-03-07T07:18:18Z
---

## Scope

- [x] Confirm how migrated EV2 tests are tagged and pick the least-fragile command to run the whole migrated set.
- [x] Run the full migrated EV2 Cerberus suite with random PORT and MIX_ENV=test.
- [x] Summarize the result and note any failing files or blockers.

## Summary of Changes

Ran the full tagged migrated EV2 Cerberus suite from /Users/ftes/src/ev2-copy with:
- PORT=4871 MIX_ENV=test mix test --only cerbrerus --include integration

Result:
- 275 tests, 5 failures, 6 skipped, 4723 excluded

Observed failures during the full run:
- /Users/ftes/src/ev2-copy/test/ev2_web/live/project_settings_live/public_notifications_test.exs:16
- /Users/ftes/src/ev2-copy/test/ev2_web/live/project_settings_live/dates_test.exs:27
- /Users/ftes/src/ev2-copy/test/ev2_web/live/user_live/preferences_form_test.exs:18
- /Users/ftes/src/ev2-copy/test/ev2_web/live/project_settings_live/notifications_test.exs:84
- one additional failure was present in the full run but was not captured cleanly before rerun; it appears to have been another live-side timing/value assertion in the same migrated set

Reran only the failed subset with:
- PORT=4886 MIX_ENV=test mix test --only cerbrerus --include integration --failed

Result:
- 5 tests, 2 failures

Persistent failures on rerun:
- /Users/ftes/src/ev2-copy/test/ev2_web/live/project_settings_live/notifications_test.exs:84
- /Users/ftes/src/ev2-copy/test/ev2_web/live/user_live/preferences_form_test.exs:18

The other 3 failures from the full run did not reproduce immediately on --failed and currently look flaky/live-timing-sensitive rather than hard failures.
