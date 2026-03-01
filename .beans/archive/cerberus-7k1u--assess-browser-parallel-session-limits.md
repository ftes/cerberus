---
# cerberus-7k1u
title: Assess browser parallel session limits
status: completed
type: task
priority: normal
created_at: 2026-03-01T14:14:19Z
updated_at: 2026-03-01T14:15:17Z
---

Answer whether limiting parallel browser user sessions is needed for performance/reliability.

## Todo
- [x] Review runtime/session architecture
- [x] Check current test concurrency defaults
- [x] Provide recommendation

## Summary of Changes
- Confirmed runtime-level sharing: one runtime webdriver session and BiDi socket per browser name, reused across owners.
- Confirmed per-test/user isolation: each browser session creates a distinct user context + browsing context process, so concurrency still scales resource usage.
- Confirmed ExUnit concurrency is not explicitly capped in test helper (`ExUnit.start()` with defaults).
- Recommendation: cap browser-tagged test parallelism when flake or startup errors appear; keep broader suite parallel.
