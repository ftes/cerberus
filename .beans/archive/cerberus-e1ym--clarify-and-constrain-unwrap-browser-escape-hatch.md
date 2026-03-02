---
# cerberus-e1ym
title: Clarify and constrain unwrap browser escape hatch usage
status: completed
type: task
priority: normal
created_at: 2026-02-28T15:12:09Z
updated_at: 2026-03-02T05:40:15Z
---

Boundary scope: unwrap can expose unstable browser internals not intended as public contract.

## Scope
- Document current instability/constraints clearly
- Define guardrails for usage in tests
- Decide whether to harden, hide, or replace this escape hatch for browser internals

Research note: check Capybara/Cuprite behavior first; if unclear, fallback to Playwright JS/docs for confirmation.


## Todo
- [x] Constrain browser unwrap payload behind a dedicated native handle type
- [x] Update unwrap tests to validate constrained browser handle usage
- [x] Clarify escape-hatch guardrails in docs
- [x] Run format, targeted tests, and precommit
- [x] Summarize and complete bean


## Summary of Changes
- Introduced a constrained browser unwrap payload type: Cerberus.Browser.Native.
- Updated Cerberus.unwrap/2 for browser sessions to pass Cerberus.Browser.Native instead of a raw internals map.
- Added accessors user_context_pid/1 and tab_id/1 plus opaque-type documentation for guarded usage.
- Updated unwrap integration tests to assert on the constrained handle and accessor-based reads.
- Clarified escape-hatch guardrails in docs and Cerberus moduledoc.
