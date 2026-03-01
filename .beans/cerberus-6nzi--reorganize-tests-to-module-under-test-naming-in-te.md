---
# cerberus-6nzi
title: Reorganize tests to module-under-test naming in test/cerberus
status: completed
type: task
priority: normal
created_at: 2026-03-01T17:33:28Z
updated_at: 2026-03-01T18:58:02Z
parent: cerberus-whq9
---

Phase 4: Test layout and naming cleanup.

Goals:
- Place tests under test/cerberus using ModuleTest naming for module-focused suites.
- Keep integration contract suites in test/cerberus with CerberusTest.* module namespace.

## Todo
- [x] Map each current core behavior file to concrete module-under-test files
- [x] Move first integration batch into test/cerberus/cerberus_test (api_examples, assertion_filter_semantics, form_actions, form_button_ownership, live_nested_scope_behavior)
- [x] Rename moved integration modules from Cerberus.Core*Test to CerberusTest.*Test
- [x] Run format and precommit for the first integration batch
- [x] Relocate/rename remaining core behavior files to target module paths and names
- [x] Complete integration contract split into CerberusTest.* modules under test/cerberus

## Summary of Changes
- Moved all public API integration behavior suites from `test/cerberus/core` into `test/cerberus/cerberus_test`.
- Renamed integration test modules from `Cerberus.Core*Test` to `CerberusTest.*Test` to match top-level public API coverage naming.
- Updated README test commands to the new `test/cerberus/cerberus_test` paths.
- Validated with `mix test test/cerberus/cerberus_test` and `mix precommit`.
