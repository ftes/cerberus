---
# cerberus-6nzi
title: Reorganize tests to module-under-test naming in test/cerberus
status: in-progress
type: task
priority: normal
created_at: 2026-03-01T17:33:28Z
updated_at: 2026-03-01T18:52:13Z
parent: cerberus-whq9
---

Phase 4: Test layout and naming cleanup.

Goals:
- Place tests under test/cerberus using ModuleTest naming for module-focused suites.
- Keep integration contract suites in test/cerberus with CerberusTest.* module namespace.

## Todo
- [ ] Map each current core behavior file to concrete module-under-test files
- [x] Move first integration batch into test/cerberus/cerberus_test (api_examples, assertion_filter_semantics, form_actions, form_button_ownership, live_nested_scope_behavior)
- [x] Rename moved integration modules from Cerberus.Core*Test to CerberusTest.*Test
- [x] Run format and precommit for the first integration batch
- [ ] Relocate/rename remaining core behavior files to target module paths and names
- [ ] Complete integration contract split into CerberusTest.* modules under test/cerberus
