---
# cerberus-grcs
title: Document event-waiter race-safety decision
status: completed
type: task
priority: normal
created_at: 2026-03-03T21:32:30Z
updated_at: 2026-03-03T21:43:44Z
---

Record policy that event-driven waits must register and block in owning process (tab/user-context) to avoid missed events from external polling.

## Summary of Changes

Documented a maintainer policy in docs/architecture.md: browser event waits must register and block in the owning process (browsing context or user context), not in external polling loops. Added the rationale and timeout diagnostics rule.
