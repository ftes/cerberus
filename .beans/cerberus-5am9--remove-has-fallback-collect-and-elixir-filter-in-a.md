---
# cerberus-5am9
title: Remove has fallback collect and Elixir filter in action paths
status: completed
type: task
priority: normal
created_at: 2026-03-03T11:30:52Z
updated_at: 2026-03-03T19:02:06Z
parent: cerberus-dsr0
---

Eliminate fallback path that collects broad candidates and applies has filtering in Elixir.\n\nScope:\n- [x] Evaluate has and composition filters entirely in browser helper resolution for action ops.\n- [x] Keep and/or nested composition semantics intact.\n- [x] Add parity harness cases for has composition under browser and static expectations.

## Summary of Changes
- Removed legacy fallback action paths that collected broad candidates and applied has filtering in Elixir; browser actions now resolve via the in-browser helper pipeline only.
- Deleted unused browser expression wrappers tied to the removed fallback action paths to prevent reintroduction of split semantics.
- Added parity-corpus coverage for nested and/or composition inside has(...) on submit actions to lock browser/static behavior parity.
- Verified parity corpus and focused action/link suites after the cleanup.
