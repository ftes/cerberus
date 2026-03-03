---
# cerberus-ej95
title: Allow accept/reject dialog (inspired by PhoenixTest.Playwright.with_dialog)
status: completed
type: feature
priority: normal
created_at: 2026-03-03T20:29:56Z
updated_at: 2026-03-03T20:50:58Z
---

Extend Cerberus.Browser.with_dialog to support explicit accept/confirm and reject/cancel behavior, inspired by PhoenixTest.Playwright.with_dialog callback semantics.

## Todo
- [x] Design public API options for dialog decision (accept/reject) and optional prompt text.
- [x] Implement browser extension flow to pass accept flag (and prompt text when provided) to browsingContext.handleUserPrompt.
- [x] Add tests for accept, reject, prompt text, and backward-compatible default behavior.
- [x] Update README/docs examples for dialog handling.

## Summary of Changes
Added `accept: boolean` and optional `prompt_text` support to `Browser.with_dialog/3` options.
Updated dialog prompt handling to pass accept/prompt parameters through both normal and fallback `browsingContext.handleUserPrompt` paths.
Added option validation for `prompt_text` requiring `accept: true` and expanded browser extension tests for explicit confirm behavior.
Updated README and cheatsheet examples to show dialog accept/reject control in browser flows.
