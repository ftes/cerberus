---
# cerberus-etv3
title: Inventory phoenix_test LiveView oddities into replication beans
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:29:07Z
updated_at: 2026-02-27T11:31:49Z
parent: cerberus-zqpu
---

## Scope
Audit phoenix_test tests for LiveView oddities/quirks and create one bean per test or coherent test group that Cerberus should replicate. Include source snippets in each bean.

## Done When
- [x] Relevant phoenix_test test files are reviewed for LiveView oddities/quirks.
- [x] One bean per selected test/group is created with snippet(s) and rationale.
- [x] Parent inventory bean includes summary and is completed.

## Summary of Changes
- Reviewed phoenix_test LiveView-focused tests in:
  - `test/phoenix_test/live_test.exs`
  - `test/phoenix_test/live_view_timeout_test.exs`
  - `test/phoenix_test/live_view_watcher_test.exs`
  - `test/phoenix_test/live_view_bindings_test.exs`
- Created 11 replication task beans, each with source snippets and Done When criteria:
  - `cerberus-84yj`, `cerberus-294u`, `cerberus-d7t8`, `cerberus-6i8f`, `cerberus-9e6l`, `cerberus-82ng`, `cerberus-0xy3`, `cerberus-1ds6`, `cerberus-7ak7`, `cerberus-htzz`, `cerberus-hafn`
- Parented created tasks under feature `cerberus-zqpu` because task->task parenting is not allowed by beans constraints.
