---
# cerberus-nlic
title: Harden browser startup against intermittent Chrome session-creation flakes
status: todo
type: task
priority: deferred
created_at: 2026-03-01T16:13:52Z
updated_at: 2026-03-01T16:13:52Z
---

Track as future improvement only if this flake recurs.

Goal:
- Reduce impact of intermittent webdriver session creation failures where Chrome exits during startup.

Proposed scope when prioritized:
- Add targeted retry for transient session-not-created Chrome startup failures.
- Capture and surface chromedriver verbose logs/artifacts on startup failures.
- Validate behavior in CI under repeated browser session start/stop cycles.

Exit criteria:
- Intermittent startup failures are retried once (or configured) and produce actionable logs when unrecoverable.
