---
# cerberus-3ruh
title: Fix browser_extensions with_dialog failing test
status: completed
type: bug
priority: normal
created_at: 2026-03-02T05:59:55Z
updated_at: 2026-03-02T06:01:54Z
---

## Problem
A test in test/cerberus/browser_extensions_test.exs is failing in CI.

## TODO
- [x] Reproduce failure in browser_extensions_test
- [x] Implement targeted test fix
- [x] Run format and targeted test file
- [x] Run precommit
- [x] Add summary of changes

## Summary of Changes
- Reworked `with_dialog/3` action-task execution to capture callback exceptions/throws/exits as values instead of crashing the task process.
- Added structured helpers to unwrap captured callback outcomes and raise deterministic `AssertionError`s with the original formatted error text.
- Preserved existing callback-failure assertions while removing the noisy asynchronous task crash log emitted during `browser_extensions_test`.
- Verified with `mix test --warnings-as-errors test/cerberus/browser_extensions_test.exs` and `mix precommit`.
