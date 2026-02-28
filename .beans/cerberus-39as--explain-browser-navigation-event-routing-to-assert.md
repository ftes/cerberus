---
# cerberus-39as
title: Explain browser navigation event routing to assert_path
status: completed
type: task
priority: normal
created_at: 2026-02-28T20:09:58Z
updated_at: 2026-02-28T20:11:19Z
---

Trace how browser navigation events propagate through Cerberus runtime/driver layers to wake assertions waiting on path changes.

## Summary of Changes

Traced browser navigation signal flow from WebSocket/BiDi events through browsing context readiness and snapshot updates to session.current_path, then mapped how assert_path consumes that state without its own waiting/retry loop.
