---
# cerberus-2aby
title: Use LiveView diff events to drive timeout retries
status: completed
type: feature
priority: normal
created_at: 2026-02-28T06:04:51Z
updated_at: 2026-02-28T06:14:04Z
---

Replace fixed-interval assertion polling in live timeout handling with an event-assisted loop driven by LiveView/ClientProxy diff signals, keeping a polling fallback for safety.\n\n## Objectives\n- react quickly to actual LiveView updates\n- reduce unnecessary retry latency\n- keep behavior deterministic across LiveView versions\n\n## Todo\n- [x] Inventory stable message points in LiveViewTest/ClientProxy that indicate applied diffs\n- [x] Extend Cerberus watcher to surface diff/update notifications for watched views\n- [x] Refactor timeout loop to attempt immediately, then wait on watcher events with bounded fallback polling\n- [x] Add conformance/unit tests for event-driven retries, redirects, and death fallbacks\n- [x] Document semantics and LiveView-version caveats

## Summary of Changes
- Extended `Cerberus.LiveViewWatcher` to watch LiveViewTest proxy traffic for updates: it now traces watched proxy receives and emits `{:watcher, view_pid, :live_view_diff}` when matching `diff` messages or reply payloads with `:diff` arrive.
- Added proxy-trace lifecycle management (start/stop, monitor cleanup, watcher termination cleanup) while preserving existing redirect/death notifications.
- Refactored `Cerberus.LiveViewTimeout` to use deadline-based retries with immediate first attempt and event-assisted wakeups (`:live_view_diff`) plus bounded polling fallback.
- Added timeout test coverage for immediate retry on diff notifications and watcher unit coverage for diff/reply topic handling.
- Updated timeout semantics docs in `README.md`/`doc/readme.md`, including a caveat that this watcher path depends on LiveViewTest `ClientProxy` internals.
- Validation: `mix test` and `mix precommit` pass.
