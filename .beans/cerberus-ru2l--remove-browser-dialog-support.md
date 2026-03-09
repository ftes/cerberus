---
# cerberus-ru2l
title: Remove browser dialog support
status: completed
type: task
priority: normal
created_at: 2026-03-09T17:13:16Z
updated_at: 2026-03-09T17:28:50Z
---

Remove dialog support from Cerberus with a clean cut: delete public dialog APIs, remove browser transport/dialog state handling, update docs and tests, and verify the full test gate.

## Summary of Changes

- Removed browser dialog support completely: deleted the public assert_dialog API, dialog timeout schema, dialog-aware evaluate fallback, and all dialog event tracking/state in the browser transport.
- Removed dialog-specific browser tests and fixture behavior, and simplified the extension coverage to keep keyboard, drag, popup, download, cookies, and evaluate_js coverage.
- Updated docs and documentation examples to remove dialog references and to prefer locator sigils over constructor functions where the examples stay readable.
