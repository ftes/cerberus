---
# cerberus-cte0
title: Fix remaining Firefox behavioral test failures
status: completed
type: bug
priority: normal
created_at: 2026-03-14T22:26:50Z
updated_at: 2026-03-14T22:35:43Z
---

Reproduce and fix the remaining Firefox-lane failures in live select, deferred browser settle, and browser keyboard blur behavior, then rerun focused coverage.

## Notes
- focused Firefox repro shows the real driver bug is in browser action settle: delayed and slow non-live submit-button clicks can return before navigation starts, because the current post-click grace period is too short for the deferred submit fixture
- live select and browser blur did not fail in focused Firefox runs, so those still look like suite-load timing sensitivity rather than deterministic driver breakage

## Summary of Changes
- fixed the Firefox-only non-live submit settle race by preserving the pre-click path in the browser action helper and retrying post-click readiness while the session is still settled on that original path, instead of trusting a single fixed grace delay
- increased the click action timeout in the two non-live submit settle tests so the click itself has enough budget to await delayed navigation under full-suite Firefox load while keeping post-click assertions at timeout 0
- hardened the suite-only Firefox races by increasing the live-select save assertion timeout to 1000ms and the browser blur/tab assertions to 2000ms
- verified the affected focused Firefox files pass and reran the full Firefox lane successfully: 643 tests, 0 failures, 1 skipped
