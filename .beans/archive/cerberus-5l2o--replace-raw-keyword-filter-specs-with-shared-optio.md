---
# cerberus-5l2o
title: Replace raw keyword filter specs with shared option types
status: completed
type: task
priority: normal
created_at: 2026-03-02T13:19:33Z
updated_at: 2026-03-02T13:44:10Z
---

Scope:
- [x] Replace raw keyword filter specs in query module with shared filter types
- [x] Replace raw keyword filter specs in path module with shared option types
- [x] Replace raw keyword filter specs in html module with shared option types
- [x] Ensure types remain consistent with current runtime behavior
- [x] Run format, targeted tests, and precommit
- [x] Update bean summary and mark completed

## Summary of Changes
- Switched Query specs to shared option aliases for text, state, and count filters.
- Switched Path specs to shared path query and path match option types.
- Switched Html locator filter specs to shared locator filter option types.
- Kept runtime behavior unchanged while narrowing public and internal contracts.
- Ran mix format, targeted tests, and mix precommit. Precommit fails due unrelated Credo findings in lib/mix/tasks/cerberus.migrate_phoenix_test.ex.
