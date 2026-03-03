---
# cerberus-cbgm
title: Clarify AGENTS browser test guidance
status: completed
type: task
priority: normal
created_at: 2026-03-03T15:22:42Z
updated_at: 2026-03-03T15:23:05Z
---

Goal: update AGENTS.md wording to remove stale guidance about separate browser reruns and reflect current mixed-driver behavior.

## Tasks
- [x] Locate current browser test guidance in AGENTS.md
- [x] Replace stale line with clarified guidance
- [x] Verify diff and complete bean with summary

## Summary of Changes
- Updated AGENTS.md to replace stale guidance about separately rerunning live/static tests in a browser lane.
- Added clarified guidance that mixed-driver suites already cover real-browser validation and that browser/runtime changes should run at least one mixed-driver module with real Chrome.
- Updated adjacent Codex note from browser-tag wording to real-browser wording for consistency.
