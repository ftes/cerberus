---
# cerberus-sq9e
title: Handle option/2 text nodes in migration rewrite
status: completed
type: bug
priority: normal
created_at: 2026-03-05T05:44:36Z
updated_at: 2026-03-05T06:01:16Z
---

Migration rewrite for LiveView tests crashes on option text tuples (example: {:option, {:text, [line: 208], ["Main"]}}), causing file rewrite to be skipped.

## Todo

- [x] Reproduce the failure path in migrator rewrite logic
- [x] Implement AST rewrite support for option text tuple shape
- [x] Add/adjust migration tests covering this tuple case
- [x] Run format and targeted tests
- [x] Add summary of changes and mark completed

## Summary of Changes

- Reproduced formatter crash in migration rewrites for local select calls with string option values.
- Updated select option canonicalization to preserve original keyword AST key nodes while replacing only the option value.
- Switched generated text() option AST nodes to Sourceror-parsed expressions so inserted nodes are formatter-compatible.
- Added regression test coverage for local select(..., option: "...") rewrites and verified no rewrite-failed warning.
- Ran mix format and targeted migration task tests successfully.

## Follow-up Adjustments

- Updated select option rewrites to emit locator sigils for literal option values instead of text call forms.
- Fixed locator index detection for piped two argument action calls so the main locator argument is canonicalized correctly.
- Added migration regression coverage for piped select with option literal rewrites.
- Revalidated with mix precommit, full mix test, mix test only slow, and ev2 migration runs without rewrite failed warnings.
