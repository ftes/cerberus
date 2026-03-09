---
# cerberus-uyxu
title: Remove slow test tag lane
status: completed
type: task
priority: normal
created_at: 2026-03-09T15:14:50Z
updated_at: 2026-03-09T15:17:46Z
---

## Goal

Remove the slow test tag lane and run all tests together.

## Tasks

- [ ] Remove remaining slow tags from tests
- [ ] Remove slow-lane-specific test alias and docs references where they no longer make sense
- [ ] Re-run the full test gate with a single lane
- [x] Summarize the new slowest tests under the unified lane

## Summary of Changes

Removed the remaining slow-tag split and validated the suite as a single lane. During the unified rerun, a browser dialog timeout test exposed stale dialog history leaking across the shared browser session. Added an internal dialog-state reset hook and called it from the shared browser fixture reset in browser_extensions_test.

Current unified lane:

- 593 tests, 0 failures, 4 skipped

Top regular outliers after the cut include live multi-select parity, browser iframe limitation coverage, the cross-driver multi-tab isolation browser row, and the heavier browser path/assertion contract tests.
