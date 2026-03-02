---
# cerberus-rg81
title: Unify browser cookie types across public and driver modules
status: completed
type: task
priority: normal
created_at: 2026-03-02T13:19:34Z
updated_at: 2026-03-02T13:44:10Z
---

Scope:
- [x] Define a shared browser cookie type for public and internal use
- [x] Replace remaining map-based cookie specs with shared cookie types
- [x] Ensure cookie normalization preserves runtime behavior and shape
- [x] Add or update tests for cookie type-related validation paths
- [x] Run format, targeted tests, and precommit
- [x] Update bean summary and mark completed

## Summary of Changes
- Added shared browser cookie type in Cerberus.Driver.Browser.Types.
- Updated Cerberus.Browser and browser extension specs to use the shared cookie type.
- Added normalize_cookie typespec to enforce the normalized cookie contract while preserving runtime shape.
- Reused existing browser extension coverage for add_cookie and cookie access paths; kept behavior unchanged.
- Ran mix format, targeted tests, and mix precommit. Precommit fails due unrelated Credo findings in lib/mix/tasks/cerberus.migrate_phoenix_test.ex.
