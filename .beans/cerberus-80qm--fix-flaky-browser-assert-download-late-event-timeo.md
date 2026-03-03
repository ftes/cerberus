---
# cerberus-80qm
title: Fix flaky browser assert_download late-event timeout
status: completed
type: bug
priority: normal
created_at: 2026-03-03T21:24:49Z
updated_at: 2026-03-03T21:26:37Z
parent: cerberus-ql0l
---

Stabilize Browser.assert_download wait loop so events arriving near timeout boundary are not missed; fix failing test assert_download waits for download emitted after assertion starts.

## Todo
- [x] Reproduce/analyze timeout boundary race in browser assert_download
- [x] Patch browser wait loop to re-check events at timeout deadline
- [x] Make timing test trigger closer to real usage (single-session process)
- [x] Run format, targeted test, and precommit

## Summary of Changes

- Updated browser download wait loop to perform one final event snapshot check at deadline before raising timeout.
- Extracted timeout-error reporting into helper functions for clearer control flow and stable diagnostics.
- Updated the timing test to trigger delayed download via in-page setTimeout click instead of a cross-process session click task.
- Verified with the exact failing test location and full precommit checks.
