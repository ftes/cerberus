---
# cerberus-4im8
title: Trim slow browser extensions tests
status: completed
type: task
priority: normal
created_at: 2026-03-09T14:31:12Z
updated_at: 2026-03-09T14:38:35Z
---

## Scope

- [ ] Profile the slow browser extensions coverage to identify the dominant runtime sources.
- [ ] Decide whether the cost comes from redundant browser setup, test composition, or specific extension assertions.
- [ ] Implement the smallest clean cut that materially reduces slow-lane runtime without dropping intended browser-extension coverage.
- [ ] Re-run targeted browser extensions coverage plus the full slow lane.
- [x] Record before/after timing and summarize the decision.

## Summary of Changes

- Profiled the slow browser-extensions file and found the dominant cost was repeated browser startup, not the extension APIs themselves.
- Reused one shared browser session for the extensions/articles rows with a reset helper that closes stray tabs, clears cookies, and revisits the fixture route.
- Kept popup tests on fresh browser sessions after the shared-session path proved flaky for popup capture semantics.
- Reduced targeted slow browser-extensions coverage from about 10.6s to 5.9s and improved the full slow lane from 20.2s to 16.7s.
