---
# cerberus-xw4m
title: Trim dialog-open browser assertion test runtime
status: completed
type: bug
priority: normal
created_at: 2026-03-09T10:45:37Z
updated_at: 2026-03-09T10:52:04Z
---

## Scope

- [ ] Profile the two dialog-open browser slow tests to identify where time is spent.
- [ ] Reduce runtime without reintroducing the blocked-dialog read regression.
- [ ] Re-run targeted browser slow tests and full quality gates.
- [x] Record before/after mix test timings for the affected tests.

## Summary of Changes

The slow path was a full script.evaluate command timeout before we fell back to dialog unblocking. Browser reads now check for an already-open blocking dialog first and go straight to the dialog-aware evaluate path instead of waiting for the command timeout to expire. I also added the Chrome wording Execution context was destroyed to the transient navigation retry markers so the browser timeout assertion suite stays green under full gates.

Before/after mix test timings:
- browser_extensions dialog-open tests: 13.7s -> 1.5s
- browser_extensions slow file: 24.6s -> 6.4s
