---
# cerberus-i6jy
title: Audit current dialog support
status: completed
type: task
priority: normal
created_at: 2026-03-09T17:03:47Z
updated_at: 2026-03-09T17:06:12Z
---

## Goal

Document Cerberus's current support for browser dialogs based on the implementation, tests, and docs.

## Todo

- [x] Inspect dialog-related API and driver code
- [x] Inspect dialog tests and docs
- [x] Summarize current support and notable gaps

## Summary of Changes

- Audited the public browser dialog API, browser driver dialog tracking, dialog-aware evaluate/read fallback, and regression coverage.
- Confirmed the current contract: browser dialogs are observed and auto-accepted; prompt dialogs are auto-accepted with empty input; assert_dialog is post-hoc text assertion only.
- Identified a stale cheatsheet example that still advertises accept: true even though the current option schema rejects explicit dialog control options.
