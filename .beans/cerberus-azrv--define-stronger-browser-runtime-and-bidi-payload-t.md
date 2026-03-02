---
# cerberus-azrv
title: Define stronger browser runtime and BiDi payload types
status: completed
type: task
priority: normal
created_at: 2026-03-02T13:19:34Z
updated_at: 2026-03-02T13:44:10Z
---

Scope:
- [x] Introduce reusable types for browser runtime payload maps
- [x] Introduce reusable types for BiDi command results and errors
- [x] Replace pervasive map specs in runtime and BiDi process modules where safe
- [x] Keep interfaces stable while tightening typespec contracts
- [x] Run format, targeted tests, and precommit
- [x] Update bean summary and mark completed

## Summary of Changes
- Added Cerberus.Driver.Browser.Types with shared browser protocol payload types, BiDi response types, and readiness payload types.
- Updated Runtime and BiDi to reuse shared browser name and payload type contracts.
- Updated BrowsingContextProcess and UserContextProcess specs to return shared BiDi and readiness types instead of generic map types.
- Kept runtime behavior and process interfaces unchanged while tightening typespecs.
- Ran mix format, targeted tests, and mix precommit. Precommit fails due unrelated Credo findings in lib/mix/tasks/cerberus.migrate_phoenix_test.ex.
