---
# cerberus-vrz8
title: Replace generic observed map types with explicit result shapes
status: completed
type: task
priority: normal
created_at: 2026-03-02T13:19:34Z
updated_at: 2026-03-02T13:44:10Z
---

Scope:
- [x] Define explicit observed/result types for assertion operations
- [x] Update driver operation result specs to use explicit observed types
- [x] Update session last_result type to use the new observed union type
- [x] Align assertion formatting helpers with explicit result type contracts
- [x] Run format, targeted tests, and precommit
- [x] Update bean summary and mark completed

## Summary of Changes
- Added explicit observed, scope, operation, and result types in Session and reused them across drivers.
- Updated Driver observed and operation result aliases to use Session observed contracts.
- Added Browser session last_result field and now persist op and observed metadata in browser update_session.
- Added assertion helper specs for run_assertion, format_error, and observed_transition aligned to Session observed contracts.
- Ran mix format, targeted tests, and mix precommit. Precommit fails due unrelated Credo findings in lib/mix/tasks/cerberus.migrate_phoenix_test.ex.
