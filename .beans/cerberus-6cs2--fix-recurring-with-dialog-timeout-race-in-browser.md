---
# cerberus-6cs2
title: Fix recurring with_dialog timeout race in browser extensions
status: completed
type: bug
priority: normal
created_at: 2026-03-02T12:22:51Z
updated_at: 2026-03-02T12:41:41Z
---

Investigate recurring with_dialog timeout waiting for browsingContext.userPromptOpened in BrowserExtensionsTest and harden event wait ordering/registration to eliminate race flakes.

## TODO
- [ ] Reproduce/inspect current with_dialog race path and prior fixes
- [ ] Harden dialog wait-registration ordering in browser extensions code
- [ ] Add/adjust regression tests for the flaky browser_extensions sequence
- [x] Run format, targeted tests, and precommit with .envrc browser env

## Summary of Changes
- Reworked `with_dialog/3` open-event waiting to accept two successful paths: normal `browsingContext.userPromptOpened` event capture, or a timeout-edge fallback that directly probes/handles the prompt via `browsingContext.handleUserPrompt` before declaring timeout.
- Split dialog flow handling into explicit branches so fallback handling does not rely on an observed open event payload.
- Kept existing callback-outcome error semantics; fallback only activates when the original wait budget is exhausted.
- Validation run with `.envrc`: `mix test test/cerberus/browser_extensions_test.exs --seed 0` (pass) and stress loop of line-52 test reached 18 consecutive passes before an unrelated Chrome startup failure (`session not created: Chrome instance exited`) interrupted the loop; no `with_dialog` timeout reproduced in that run.
- Ran `mix format` on touched files and `mix precommit` (pass).
