---
# cerberus-1nb0
title: Clean up low-value completed beans
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:17:50Z
updated_at: 2026-02-27T21:18:21Z
---

## Scope
Reduce bean noise by archiving completed low-level beans that no longer add useful context.

## Done When
- [x] Completed low-level beans are identified.
- [x] Selected beans are archived.
- [x] Cleanup summary is captured.

## Summary of Changes
- Identified 73 completed/scrapped beans: 68 tasks, 3 bugs, 2 features.
- Used beans archive (CLI supports archive-all for completed/scrapped status).
- Archived 73 beans to .beans/archive/ to reduce top-level tracker noise while preserving query visibility/history.
