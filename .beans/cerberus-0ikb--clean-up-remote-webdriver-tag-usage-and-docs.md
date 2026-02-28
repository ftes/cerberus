---
# cerberus-0ikb
title: Clean up remote_webdriver tag usage and docs
status: completed
type: task
priority: normal
created_at: 2026-02-28T20:25:58Z
updated_at: 2026-02-28T20:39:26Z
---

## Goal
Remove unnecessary remote_webdriver tag-oriented usage and keep lean remote coverage documentation/tests aligned with full websocket suite runs.

## Todo
- [x] Remove remote_webdriver tag from test module and any tag-driven references
- [x] Update docs/examples to avoid special --only remote_webdriver guidance
- [x] Run format and targeted validation
- [x] Summarize changes and complete bean

## Summary of Changes
- Removed @moduletag :remote_webdriver from remote webdriver behavior test module.
- Updated docs/examples to use browser_cross_browser_runtime_test websocket invocation instead of remote_webdriver_behavior_test.
- Updated remote webdriver behavior test to no-op cleanly when setup marks the test context with skip.
- Ran mix format on touched Elixir files, mix test for remote_webdriver_behavior_test, and mix test.websocket for the same file.
