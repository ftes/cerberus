---
# cerberus-x70c
title: Implement browser assert_download via BiDi download events
status: completed
type: task
priority: normal
created_at: 2026-03-03T20:41:48Z
updated_at: 2026-03-03T20:50:47Z
parent: cerberus-ql0l
---

Implement browser-only assert_download with sequential click/assert flow using BiDi download events and tab-process buffering.

## Todo
- [x] Add browser API/assertion entrypoint for assert_download
- [x] Subscribe tab process to download events and buffer history
- [x] Implement assert_download wait/match logic (existing + future events, timeout)
- [x] Add browser tests and docs

## Summary of Changes
Implemented `Browser.assert_download/3` as a browser-only extension with timeout validation.
Subscribed per-tab browsing context processes to BiDi download events and stored bounded per-tab download history.
Added wait/match logic that checks existing events first, then waits for future events up to timeout (non-consuming matches).
Added fixture download endpoint and browser extension tests, plus README/cheatsheet docs for download assertion usage.
