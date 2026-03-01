---
# cerberus-ke49
title: Add locator chaining and composition
status: completed
type: feature
priority: normal
created_at: 2026-03-01T16:00:44Z
updated_at: 2026-03-01T21:52:52Z
blocked_by:
    - cerberus-1xnx
---

Add composable locator pipelines (chaining/filtering/has-descendant style constraints) with deterministic cross-driver semantics and browser-oracle verification.

## Prerequisite
- Complete cerberus-1xnx rich locator oracle corpus updates first; preserve and extend that corpus as this bean lands.


## Todo
- [x] Define chaining API shape and option normalization rules
- [x] Implement chained locator resolution in static/live/browser paths
- [x] Add oracle and parity tests for chaining semantics and edge cases
- [x] Run format, focused tests, and precommit
- [x] Summarize and complete bean


## Summary of Changes
- Added locator composition with has across helper constructors and locator normalization.
- Implemented has normalization and validation for nested css, text, and testid locators, with deterministic errors for unsupported nested kinds.
- Wired has filtering into static and live HTML candidate matching, including live clickable button matching.
- Added browser parity by capturing candidate outer_html and applying the same locator filter semantics against HTML fragments.
- Expanded locator tests and parity coverage for has behavior, including live and browser integration cases.
- Updated docs in README, getting-started, and cheatsheet with has usage examples.
