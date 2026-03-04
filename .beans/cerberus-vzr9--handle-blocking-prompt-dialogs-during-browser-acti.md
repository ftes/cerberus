---
# cerberus-vzr9
title: Handle blocking prompt dialogs during browser action/assert ops
status: completed
type: bug
priority: normal
created_at: 2026-03-04T09:35:59Z
updated_at: 2026-03-04T09:42:15Z
---

Add regression tests for browser action/assert operations blocked by prompt dialogs, and implement reliable unblocking strategy.

- [x] Add action-op regression test for blocking prompt
- [x] Add assert-op regression test for blocking prompt
- [x] Implement shared prompt-unblocking for eval-backed action/assert paths
- [x] Run mix format
- [x] Run targeted browser tests
- [x] Update bean summary and mark completed

## Summary of Changes

Added prompt-dialog fixture support in browser extension test page (button + status output).
Added two browser regressions:
- click action survives a blocking prompt opened by the clicked target
- assert_has survives a blocking prompt that is already open
Implemented shared eval prompt-unblocking in a new internal module (Cerberus.Driver.Browser.Evaluate) and wired it into both driver action/assert eval paths and Browser extension eval paths.
The unblocking logic is event-driven and prompt-specific: it listens for opened dialogs while script.evaluate is in-flight, dismisses only prompt dialogs, and preserves confirm/alert behavior for assert_dialog flows.

Validation:
- mix format
- source .envrc && mix test test/cerberus/browser_extensions_test.exs
- source .envrc && mix test test/cerberus/documentation_examples_test.exs
