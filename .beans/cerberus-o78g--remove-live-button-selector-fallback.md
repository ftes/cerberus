---
# cerberus-o78g
title: Remove live button selector fallback
status: completed
type: task
priority: normal
created_at: 2026-03-11T08:26:56Z
updated_at: 2026-03-11T08:32:05Z
---

## Goal

Remove the selector-based `LiveViewTest.element/3` fallback for live button clicks and validate that metadata-first dispatch is sufficient.

## Todo

- [x] Remove live button fallback path
- [x] Run targeted live click and portal tests
- [x] Summarize any regressions or confirm removal is safe

## Summary of Changes

- Removed the live-driver selector-based `LiveViewTest.element/3` fallback for button clicks so live buttons now use metadata-driven dispatch as the only path.
- Fixed the resulting trigger-action regression by propagating metadata-path driver errors through `click_live_button/3` instead of crashing on unmatched cases.
- Verified the isolated regression with `source .envrc && PORT=4144 mix test test/cerberus/live_trigger_action_behavior_test.exs`.
- Verified the full suite with `source .envrc && PORT=4145 mix test` (`599 tests, 0 failures`).

## Result

- The fallback is not required for the current live button coverage.
