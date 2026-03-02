---
# cerberus-f9yj
title: Tighten session option types and validate entry points
status: completed
type: task
priority: normal
created_at: 2026-03-02T13:19:33Z
updated_at: 2026-03-02T13:44:10Z
---

Scope:
- [x] Define explicit session option types for public session constructors
- [x] Route session option validation through shared options validators
- [x] Replace broad keyword specs at entry points with concrete option types
- [x] Add or update tests for invalid session option handling
- [x] Run format, targeted tests, and precommit
- [x] Update bean summary and mark completed

## Summary of Changes
- Added explicit session option types in Cerberus.Options for common and browser constructors, including nested browser overrides.
- Wired session option validation into session/1, session(:phoenix, opts), session(:browser, opts), and browser alias constructors.
- Tightened entry-point specs to use shared session option types instead of generic keyword lists.
- Added timeout_defaults coverage for invalid browser readiness and nested browser option shapes.
- Ran mix format, targeted tests, and mix precommit. Precommit fails due unrelated Credo findings in lib/mix/tasks/cerberus.migrate_phoenix_test.ex.
