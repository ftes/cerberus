---
# cerberus-2094
title: Preserve :role locators through matcher pipeline
status: completed
type: feature
priority: normal
created_at: 2026-03-04T08:13:36Z
updated_at: 2026-03-04T08:22:15Z
---

Keep role locators as kind :role from normalization through driver matching (Elixir + browser JS) instead of rewriting to explicit kinds up front, while preserving current diagnostics quality (including candidate hints).

Scope:
- [x] Keep normalized locator kind as :role and retain role metadata
- [x] Add shared role-resolution mapping in Elixir and browser JS matcher paths
- [x] Update static/live/browser matching to consume resolved role semantics
- [x] Preserve/improve existing error diagnostics and candidate suggestions
- [x] Add/adjust tests for role locator behavior and diagnostics
- [x] Run format + precommit

## Summary of Changes

- Kept role locators as kind role through normalization and sigil parsing, with role metadata retained in locator opts.
- Added shared role resolution in Locator (resolved_kind and resolve_role_kind) so Elixir matchers consume role semantics consistently.
- Updated assertion normalization, locator ops shaping, static HTML matching, live clickable matching, and browser locator payload plus browser JS matcher logic to resolve role locators at execution time.
- Preserved diagnostics behavior by keeping candidate collection paths unchanged and added a role-based failure test that still reports possible candidates.
- Updated locator unit tests to assert role kind preservation and explicit role to matcher-kind resolution mapping.
- Ran targeted tests plus slow locator parity and completed format plus precommit successfully.
