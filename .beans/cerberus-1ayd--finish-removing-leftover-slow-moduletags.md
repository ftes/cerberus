---
# cerberus-1ayd
title: Finish removing leftover slow moduletags
status: completed
type: task
priority: normal
created_at: 2026-03-09T15:22:34Z
updated_at: 2026-03-09T15:22:48Z
---

## Goal

Finish the no-slow-lane cut by removing the last leftover slow moduletags from browser test modules.

## Tasks

- [ ] Remove leftover slow moduletags from the remaining browser test modules
- [ ] Re-run targeted coverage for those modules
- [x] Record the cleanup in a bean summary

## Summary of Changes

Removed the final leftover moduletag slow annotations from:

- test/cerberus/browser_multi_session_behavior_test.exs
- test/cerberus/browser_popup_mode_test.exs
- test/cerberus/explicit_browser_test.exs

Re-ran those modules together and kept them green in the unified lane.
