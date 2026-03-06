---
# cerberus-lhp6
title: Verify actionability and visibility parity across browser and non-browser
status: completed
type: task
priority: normal
created_at: 2026-03-06T09:23:06Z
updated_at: 2026-03-06T09:26:46Z
---

## Goal
Confirm whether Cerberus mirrors Playwright actionability checks in browser and non-browser drivers, and whether visibility checks are mirrored (browser-only if needed).

## Todo
- [x] Inspect browser actionability checks
- [x] Inspect non-browser actionability checks
- [x] Inspect browser visibility checks
- [x] Summarize parity status for user

## Summary of Changes
Reviewed browser, static, and live action paths plus locator matching layers.
Confirmed browser actionability currently enforces attachment + scroll-into-view + visibility, with disabled checks only for select/choose/check/uncheck/upload.
Confirmed non-browser drivers do not implement browser-style visibility actionability checks; disabled handling is partial and mostly operation-specific or opt-in via state filters.
