---
# cerberus-itv5
title: Always auto-accept browser dialogs and assert past events
status: completed
type: bug
priority: normal
created_at: 2026-03-04T10:32:29Z
updated_at: 2026-03-04T10:41:28Z
---

## Goal

Adopt a simpler browser dialog policy:
- Always auto-accept dialogs opened during eval-backed operations.
- For prompt dialogs, auto-accept with empty string input.
- Keep assert_dialog as a post-hoc assertion on observed dialog events.

## Todo

- [x] Update eval dialog unblocking to always accept (prompt => empty value)
- [x] Align assert_dialog behavior/messages with post-hoc assertion model
- [x] Update public docs for dialog policy limitations
- [x] Add/adjust regression tests for auto-accept and prompt value semantics
- [x] Run format + targeted tests + precommit
- [x] Commit code and bean file

## Summary of Changes

- Changed browser eval dialog unblocking to always accept alert/confirm dialogs and accept prompt dialogs with empty userText.
- Simplified Browser.assert_dialog so it asserts dialog text from active or recent observed events and auto-accepts any still-open matched dialog.
- Removed explicit assert_dialog dialog-control options (accept and prompt_text) from option schema and validation.
- Updated Browser.assert_dialog function docs to describe auto-accept policy and prompt empty-value behavior.
- Updated browser extension and documentation example tests to assert new confirmed/empty prompt outcomes and updated invalid-option coverage.
- Ran mix format, targeted browser docs tests, and mix precommit successfully.
