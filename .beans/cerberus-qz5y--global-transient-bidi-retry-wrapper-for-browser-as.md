---
# cerberus-qz5y
title: Global transient BiDi retry wrapper for browser assertion evals
status: completed
type: task
priority: normal
created_at: 2026-03-03T13:12:26Z
updated_at: 2026-03-03T13:22:46Z
---

Implement a shared Elixir-side retry wrapper for transient BiDi navigation/context errors while preserving in-browser wait loops as the fast path.\n\nScope:\n- [ ] Add one shared transient error classifier in browser driver.\n- [ ] Add one shared retry-until-deadline helper around eval_json for assertion/path operations.\n- [ ] Apply helper to browser text/path assertion eval paths.\n- [ ] Reuse helper at other navigation-sensitive eval call sites where immediate transient failures currently leak.\n- [ ] Add/adjust tests for async redirect/navigate race windows.\n- [ ] Verify with repeated chrome runs and full test suites.\n- [x] Add summary of changes.

## Summary of Changes

Implemented one shared transient navigation/context error classifier plus one deadline-bounded Elixir retry wrapper for idempotent browser eval operations.

Applied deadline retry to text/path assertion evals (remaining timeout is propagated into each in-browser assertion loop attempt).

Reused the same retry helper across navigation-sensitive read call sites: browser HTML snapshot reads, current path refresh, within scope snapshots, iframe access checks, clickable/form/file inspection reads, and snapshot reads.

Simplified snapshot retry by delegating to the shared retry wrapper (removed bespoke retry loop logic in snapshot helper).

Added browser async-navigation coverage in timeout assertion tests to exercise assertion+path behavior across transition windows.

Verification:
- Repeated browser timeout suite 8 times (all pass).
- Focused suites: live timeout, browser timeout, path scope, live link navigation, browser iframe limitations (all pass).
- Full test suite: 438 tests, 0 failures.
- mix precommit: passed.
