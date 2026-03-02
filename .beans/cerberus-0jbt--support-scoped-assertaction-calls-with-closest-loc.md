---
# cerberus-0jbt
title: Support scoped assert/action calls with closest locator
status: completed
type: feature
priority: normal
created_at: 2026-03-02T11:49:58Z
updated_at: 2026-03-02T11:52:10Z
---

Extend closest usage beyond within/3 by adding scoped public API calls for assertions/actions (including assert_has(scope, locator)), update docs to canonical field-error example, and add tests while keeping existing within+closest coverage.

## TODO
- [x] Add scoped assert API overloads to support assert_has(scope_locator, target_locator) and refute_has(scope_locator, target_locator)
- [x] Add scoped action API overload for click to use click(scope_locator, target_locator)
- [x] Update README/getting-started docs to use canonical field-error example with scoped assert syntax
- [x] Add tests for scoped assert+closest (keep existing within+closest tests)
- [x] Run mix format, targeted tests, and mix precommit with env loaded from .envrc

## Summary of Changes
- Added scoped overloads in Cerberus for assert_has and refute_has so calls like session |> assert_has(closest(css(".fieldset"), from: label("Email")), text("can't be blank")) work without explicit within callback blocks.
- Added scoped click overload so click(scope_locator, target_locator) uses the same locator-based scoping flow.
- Updated docs to promote the canonical closest field-wrapper assertion example using scoped assert calls.
- Added tests for scoped assert and scoped click with closest while keeping existing within+closest coverage.
- Ran mix format, targeted tests, and mix precommit with browser binaries loaded from .envrc.
