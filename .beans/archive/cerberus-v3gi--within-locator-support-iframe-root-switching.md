---
# cerberus-v3gi
title: Within locator support + iframe root switching
status: completed
type: feature
priority: normal
created_at: 2026-03-02T10:47:54Z
updated_at: 2026-03-02T11:20:13Z
---

Implement locator-based within/3; static/live scope to located element; browser auto-switches root when located element is iframe (same-origin only).

## TODO
- [x] Extend within/3 to accept locator inputs and resolve a concrete scoped element
- [x] Keep static/live scoping behavior unchanged (scope to located element selector)
- [x] Add browser iframe-aware root switching for within when target element is iframe (same-origin only)
- [x] Update browser JS/assertion root resolution to understand frame-chain scope objects
- [x] Add fixtures/tests/docs for locator-within + same-origin iframe-within behavior
- [x] Run format, targeted tests, precommit, and add summary

## Summary of Changes
- Added locator-input support in `Cerberus.within/3` while preserving existing CSS-string behavior.
- Added browser `resolve_within_scope/3` to resolve locator scopes from the active document/frame and switch to iframe document roots when the matched target is a same-origin iframe.
- Added frame-chain scope support in browser JS expressions and assertion helper root resolution so scoped actions/assertions work inside iframe documents.
- Added same-origin iframe fixtures/routes and browser tests for successful iframe scoping and cross-origin rejection.
- Added cross-driver `within(css(...))` behavior test and updated docs (`README.md`, `docs/cheatsheet.md`, `docs/getting-started.md`).

## Notes (2026-03-02)
- For wrapper scoping around a field label, descendant has matching is ambiguous when wrappers are nested.
- Recommendation: keep has as descendant semantics and add explicit closest/ancestor relation support instead of implicit parent-of-label.
- Proposed API direction: closest relation on a locator composition primitive, so users can scope to nearest wrapper for label/control before asserting related errors.
