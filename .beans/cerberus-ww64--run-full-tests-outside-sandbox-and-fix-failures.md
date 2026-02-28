---
# cerberus-ww64
title: Run full tests outside sandbox and fix failures
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:26:29Z
updated_at: 2026-02-28T07:29:35Z
---

## Objective
Run the test suite outside sandbox and fix any failing tests.

## Todo
- [x] Run full test suite outside sandbox
- [x] Identify failing tests and root causes
- [x] Implement fixes
- [x] Run mix format
- [x] Re-run targeted/full tests outside sandbox
- [x] Add summary and complete bean

## Summary of Changes
- Updated stale tests to use `session()` instead of removed public driver atoms (`:auto/:static/:live`) where flows already infer static/live via navigation.
- Updated browser readiness transition detection to treat `execution contexts cleared` as a navigation-transition condition, preventing false failures immediately after navigation-triggered submits.
- Ran `mix format`, targeted failing test modules, full `mix test`, and `mix precommit`; all checks now pass.
