---
# cerberus-cte0
title: Fix remaining Firefox behavioral test failures
status: in-progress
type: bug
priority: normal
created_at: 2026-03-14T22:26:50Z
updated_at: 2026-03-14T22:29:20Z
---

Reproduce and fix the remaining Firefox-lane failures in live select, deferred browser settle, and browser keyboard blur behavior, then rerun focused coverage.

## Notes
- focused Firefox repro shows the real driver bug is in browser action settle: delayed and slow non-live submit-button clicks can return before navigation starts, because the current post-click grace period is too short for the deferred submit fixture
- live select and browser blur did not fail in focused Firefox runs, so those still look like suite-load timing sensitivity rather than deterministic driver breakage
