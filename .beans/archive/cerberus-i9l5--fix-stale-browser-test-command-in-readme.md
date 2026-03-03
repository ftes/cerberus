---
# cerberus-i9l5
title: Fix stale browser test command in README
status: completed
type: task
priority: normal
created_at: 2026-03-03T15:29:32Z
updated_at: 2026-03-03T15:30:54Z
---

Goal: update README test command(s) that reference nonexistent browser tags/lane to match current mixed-driver test layout.

## Tasks
- [x] Locate stale README command and related surrounding guidance
- [x] Update command text to current workflow
- [x] Verify diff and complete bean with summary

## Summary of Changes
- Updated stale README test commands that referenced non-existent ExUnit tags (`--only browser`, `--only explicit_browser`).
- Replaced with file-based commands that match current suite layout: `mix test test/cerberus` and `mix test test/cerberus/explicit_browser_test.exs`.
- Reworded the explanatory paragraph to clarify that browser coverage currently runs via mixed-driver suites rather than a dedicated browser tag lane.
