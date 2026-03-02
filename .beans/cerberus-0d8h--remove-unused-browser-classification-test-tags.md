---
# cerberus-0d8h
title: Remove unused browser classification test tags
status: completed
type: task
priority: normal
created_at: 2026-03-02T13:58:24Z
updated_at: 2026-03-02T13:59:05Z
---

Scope:
- [x] Remove @moduletag :browser where unused for filtering
- [x] Remove @moduletag explicit_browser: true where unused
- [x] Run format and a focused test command
- [x] Run precommit (note unrelated failures if any)
- [x] Add summary and mark completed

## Summary of Changes
- Removed unused module-level browser classification tags from:
  - test/cerberus/locator_parity_test.exs
  - test/cerberus/remote_webdriver_behavior_test.exs
  - test/cerberus/explicit_browser_test.exs
- Ran mix format on touched test files.
- Ran focused test command: mix test test/cerberus/explicit_browser_test.exs --max-failures 1 (failed locally due Chrome startup: session not created, Chrome instance exited).
- Ran mix precommit (fails on pre-existing Credo issues in lib/mix/tasks/cerberus.migrate_phoenix_test.ex).
