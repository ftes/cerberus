---
# cerberus-r1ja
title: Refactor runtime handle_info nesting for Credo
status: completed
type: bug
priority: normal
created_at: 2026-03-01T13:47:16Z
updated_at: 2026-03-01T13:48:29Z
---

Fix precommit blocker in lib/cerberus/driver/browser/runtime.ex by reducing function body nesting in handle_info.

## Todo
- [x] Inspect handle_info nesting in runtime
- [x] Refactor to satisfy Credo without behavior changes
- [x] Run docs impact check
- [x] Run mix format
- [x] Run mix precommit
- [x] Add summary of changes

## Summary of Changes
- Refactored `handle_info({:DOWN, ...})` owner cleanup flow in `Cerberus.Driver.Browser.Runtime` into focused private helpers.
- Preserved behavior while reducing function-body nesting to satisfy Credo.
- Verified docs impact: no public API changes, no docs updates needed.
- Ran `mix format` and `mix precommit`; both pass.
