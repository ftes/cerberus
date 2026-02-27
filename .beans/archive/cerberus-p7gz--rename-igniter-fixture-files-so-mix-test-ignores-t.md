---
# cerberus-p7gz
title: Rename Igniter fixture files so mix test ignores them
status: completed
type: bug
priority: normal
created_at: 2026-02-27T19:53:14Z
updated_at: 2026-02-27T19:54:42Z
---

Mix test is picking up Igniter fixture files as runnable tests, causing failures.

## Todo
- [x] Locate Igniter fixture files that match ExUnit test filename patterns
- [x] Rename fixtures so they no longer match mix test discovery
- [x] Run targeted test discovery or suite command to confirm fixtures are skipped
- [x] Add summary of changes

## Summary of Changes
- Renamed migration-source fixtures from live_test.exs and static_test.exs to live_fixture.exs and static_fixture.exs so they no longer match ExUnit test discovery patterns.
- Updated the Igniter migration task test to read fixtures from the renamed files.
- Ran mix format and verified the migration task test passes (4 tests, 0 failures).
- Confirmed no _test.exs files remain under test/support/fixtures/migration_source.
