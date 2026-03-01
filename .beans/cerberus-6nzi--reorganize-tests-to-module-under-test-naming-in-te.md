---
# cerberus-6nzi
title: Reorganize tests to module-under-test naming in test/cerberus
status: todo
type: task
created_at: 2026-03-01T17:33:28Z
updated_at: 2026-03-01T17:33:28Z
parent: cerberus-whq9
---

Phase 4: Test layout and naming cleanup.

Goals:
- Place tests under test/cerberus using ModuleTest naming for module-focused suites.
- Keep integration contract suites in test/cerberus with CerberusTest.* module namespace.

## Todo
- [ ] Map each current core behavior file to concrete module-under-test files
- [ ] Relocate/rename test files and modules to match target modules
- [ ] Split integration contract coverage into CerberusTest.* modules under test/cerberus
- [ ] Run format and precommit
