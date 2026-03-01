---
# cerberus-w4v1
title: 'Browser assertion perf phase 2: event-first scheduling'
status: completed
type: task
priority: normal
created_at: 2026-03-01T15:52:40Z
updated_at: 2026-03-01T15:55:02Z
blocked_by:
    - cerberus-5cgp
---

Reduce continuous polling cost for browser text assertions.

## Todo
- [x] Switch to event-first check scheduling with mutation-driven dirty flag
- [x] Keep coarse timer fallback for bounded waits and race safety
- [x] Validate no regression in timeout behavior

## Summary of Changes
- Changed browser text assertion wait scheduling from constant 50ms active polling to event-first checks triggered by mutation events plus a coarse fallback timer.
- Added dirty-flag scheduling so checks run when DOM actually changes while retaining a bounded-time safety heartbeat for race conditions.
- Validated timeout behavior with browser timeout assertion tests under direnv-loaded runtime.
