---
# cerberus-xzdu
title: Replicate multi-tab and parallel multi-user session test behavior
status: completed
type: task
priority: normal
created_at: 2026-02-27T19:18:05Z
updated_at: 2026-02-27T19:39:02Z
parent: cerberus-zqpu
---

## Scope
Add browser harness coverage for multi-tab workflows and parallel multi-user sessions within a single test case, ensuring isolation and deterministic behavior when actions happen concurrently.

## Focus
- Multi-tab interactions in a single user context (open/switch/close semantics).
- Parallel users within one test, each with isolated browser contexts and independent state.
- Deterministic assertions around visibility, navigation, and state propagation across tabs/sessions.

## Done When
- [x] Multi-tab tests exist and validate expected tab-level behavior.
- [x] Parallel multi-user sessions run within one test and verify strict session isolation.
- [x] Flakiness-sensitive cases are covered with stable synchronization points.
- [x] Harness/docs updates are included when semantics or strategy change.

## Summary of Changes
- Extended `Cerberus.Driver.Browser.UserContextProcess` with deterministic tab management primitives:
  - `open_tab/1`
  - `switch_tab/2`
  - `close_tab/2`
  - `tabs/1`
  - `active_tab/1`
- Updated user-context state tracking to manage multiple `BrowsingContextProcess` workers and active-tab selection after tab close/down events.
- Added browser conformance tests in `test/core/browser_multi_session_conformance_test.exs` covering:
  - single-user multi-tab open/switch/close workflows,
  - concurrent multi-user browser sessions with strict isolation under parallel actions.
- Updated browser topology ADR with the multi-tab active-tab management behavior.

## Validation
- `mix test test/core/browser_multi_session_conformance_test.exs`
- `mix test test/core/browser_multi_session_conformance_test.exs test/core/live_navigation_test.exs test/core/path_scope_conformance_test.exs`
- `mix test test/core`
- `mix precommit` (Credo passes; Dialyzer still reports existing baseline project warnings)
