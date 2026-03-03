---
# cerberus-gld0
title: Replace with_dialog with assert_dialog and add timing coverage
status: completed
type: task
priority: normal
created_at: 2026-03-03T21:00:31Z
updated_at: 2026-03-03T21:11:29Z
---

Replace browser with_dialog helper with sequential assert_dialog(text, opts), support matching already-open and future dialogs, update docs/tests, and confirm assert_download timing coverage.

## Todo

- [x] Replace Browser.with_dialog API with Browser.assert_dialog(text_locator, opts)
- [x] Track dialog state/history in browser tab process for sequential dialog assertions
- [x] Add tests for already-open vs opens-after assert_dialog timing
- [x] Confirm/add equivalent timing coverage for assert_download
- [x] Update docs/examples to remove with_dialog usage

## Summary of Changes

- Removed callback-based Browser.with_dialog/3 and introduced sequential Browser.assert_dialog/3 with text-locator matching plus static accept/prompt_text options.
- Added per-tab dialog history and active-dialog tracking in browsing context processes, and surfaced this through UserContextProcess.
- Reworked browser extension tests for dialog assertions, including both requested timing cases (already-open and opens-after).
- Added a new assert_download timing test for the opens-after-assertion case; existing already-emitted non-consuming coverage remains.
- Updated README/getting-started/cheatsheet examples to use assert_dialog.
- Updated timeout-default error expectation from with_dialog/3 to assert_dialog/3.
