---
# cerberus-mk0d
title: 'Chrome-only cutover: remove Firefox and websocket execution paths'
status: completed
type: task
priority: normal
created_at: 2026-03-03T12:29:21Z
updated_at: 2026-03-03T12:57:20Z
---

## Goal
Make browser support and CI explicitly chrome-only for now, remove firefox-specific runtime handling, and disable websocket lanes.

## Todo
- [x] Update AGENTS.md with chrome-only policy and no-firefox/no-websocket instruction.
- [x] Disable firefox and websocket lanes in CI workflows.
- [x] Remove firefox-specific branching from browser runtime code paths.
- [x] Align local test defaults/scripts to chrome-only usage.
- [x] Run chrome browser test validation and document results.
- [x] Add summary of changes.

## Summary of Changes
- Added a chrome-only execution rule to AGENTS.md.
- Commented out websocket and firefox lanes in CI and removed firefox install/cache wiring there.
- Removed firefox-specific preload skip branches from browser runtime/user-context code.
- Switched test runtime config defaults to chrome-only binaries and webdriver lane selection.
- Updated explicit firefox-instantiating tests to chrome-only coverage and revalidated chrome browser suites.
