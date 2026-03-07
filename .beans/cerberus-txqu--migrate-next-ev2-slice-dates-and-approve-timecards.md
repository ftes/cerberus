---
# cerberus-txqu
title: 'Migrate next EV2 slice: dates and approve timecards'
status: completed
type: task
priority: normal
created_at: 2026-03-07T06:21:49Z
updated_at: 2026-03-07T06:28:04Z
---

## Scope

- [x] Migrate test/ev2_web/live/project_settings_live/dates_test.exs from PhoenixTest to Cerberus using ConnCase.
- [x] Migrate test/features/approve_timecards_test.exs from Playwright to Cerberus browser sessions using UI login.
- [x] Preserve structured assert/refute locators where PhoenixTest provided semantics beyond plain text.
- [x] Run targeted MIX_ENV=test verification in /Users/ftes/src/ev2-copy with random PORT values.

## Notes

Read /Users/ftes/src/cerberus/MIGRATE_FROM_PHOENIX_TEST.md before editing and keep debugging-oriented locator semantics in migrated assertions.

## Summary of Changes

Migrated test/ev2_web/live/project_settings_live/dates_test.exs to ConnCase plus Cerberus session(conn), tagged it with :cerbrerus, and kept the JS-dispatch helper for adding hiatus/block rows through unwrap. The stable assertions in this file are persisted field values rather than transient success toasts.

Migrated test/features/approve_timecards_test.exs to ConnCase browser sessions with UI login plus Browser.user_agent_for_sandbox metadata, tagged it with :integration and :cerbrerus, and kept structured browser assertions on the approval page alerts and flash messages. The migration needed two targeted rewrites away from the older test helpers: opening the exact approval or offer week-view routes directly instead of depending on brittle old-table links/dropdowns, and scoping the bulk-approval checkbox to the Chuck Norris row because the old page does not expose a meaningful semantic label for that control.

Verification:
- cd /Users/ftes/src/ev2-copy && eval $(direnv export zsh) && PORT=5038 MIX_ENV=test mix test test/ev2_web/live/project_settings_live/dates_test.exs test/features/approve_timecards_test.exs --include integration
- Result: 4 tests, 0 failures
