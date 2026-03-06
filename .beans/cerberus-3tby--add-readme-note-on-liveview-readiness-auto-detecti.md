---
# cerberus-3tby
title: Add README note on LiveView readiness auto-detection
status: completed
type: task
priority: normal
created_at: 2026-03-06T08:56:17Z
updated_at: 2026-03-06T08:56:32Z
---

Add one sentence in README explaining that browser readiness auto-detects LiveView roots and only waits for phx-connected when present.

## Summary of Changes

- Added one sentence in README Browser Tests section clarifying browser readiness behavior.
- New sentence explains that readiness auto-detects LiveView roots via [data-phx-session] and only waits for phx-connected when a LiveView is present.
