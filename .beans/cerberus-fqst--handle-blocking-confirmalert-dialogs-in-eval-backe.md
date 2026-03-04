---
# cerberus-fqst
title: Handle blocking confirm/alert dialogs in eval-backed ops while preserving assert_dialog
status: completed
type: bug
priority: normal
created_at: 2026-03-04T09:58:31Z
updated_at: 2026-03-04T10:09:00Z
---

Extend eval-time dialog unblocking beyond prompt to include confirm/alert for unexpected blockers, while preserving assert_dialog semantics and adding coverage for all dialog types.

- [x] Reproduce/cover blocking confirm or alert behavior in action/assert paths
- [x] Extend shared evaluator to unblock confirm/alert dialogs
- [x] Ensure assert_dialog remains reliable with auto-handled dialogs
- [x] Add assert_dialog coverage for prompt/confirm/alert types
- [x] Run mix format
- [x] Run targeted browser tests
- [x] Update bean summary and mark completed

## Summary of Changes

Extended shared browser evaluate unblocking from prompt-only to all blocking dialog types (alert/confirm/prompt), still dismissing by default when unblocking an in-flight eval.
Updated all eval-backed paths to use the shared dialog-unblocking helper so action/assert/evaluate_js operations do not hang when unexpected dialogs appear.
Hardened Browser.assert_dialog to remain usable after auto-handled dialogs by falling back to observed dialog-open events on timeout.
Added guardrails: if a matching dialog was already auto-handled, assert_dialog rejects post-hoc accept/prompt_text options with explicit errors.
Expanded fixture dialog page with alert dialog controls and added browser extension tests for:
- blocking confirm action + assert_dialog compatibility
- blocking alert during assertion operation
- assert_dialog prompt accept/prompt_text behavior
- assert_dialog alert behavior

Validation:
- mix format
- source .envrc && mix precommit
- source .envrc && mix test test/cerberus/browser_extensions_test.exs test/cerberus/documentation_examples_test.exs
