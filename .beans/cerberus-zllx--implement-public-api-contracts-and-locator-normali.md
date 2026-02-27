---
# cerberus-zllx
title: Implement public API contracts and locator normalization for slice 1
status: completed
type: task
priority: normal
created_at: 2026-02-27T07:41:00Z
updated_at: 2026-02-27T08:02:56Z
parent: cerberus-ktki
---

## Scope
Implement the first stable API contracts and parser/normalizer for text locators.

## Deliverables
- `Cerberus` module exports: `visit/3`, `click/3`, `assert_has/3`, `refute_has/3`.
- `Cerberus.Locator.normalize/1` handles:
  - string text
  - regex text
  - keyword/map `[text: ...]`
- consistent errors for unsupported forms.

## Test Cases
- [x] `assert_has(session, "Saved")` compiles and dispatches.
- [x] `assert_has(session, ~r/Sav(ed|ing)/)` compiles and dispatches.
- [x] `assert_has(session, [text: "Saved"], exact: true)` compiles and dispatches.
- [x] ambiguous/invalid locator raises `Cerberus.InvalidLocatorError`.

## Done When
- [x] API contracts are documented with typespecs.
- [x] Unit tests for locator normalization pass.

## Summary of Changes
- Added core modules: `Cerberus`, `Cerberus.Session`, `Cerberus.Locator`, `Cerberus.Query`, `Cerberus.Assertions`, and driver behaviour contracts.
- Implemented locator normalization for string, regex, and `[text: ...]` forms with explicit `Cerberus.InvalidLocatorError` handling.
- Added API and locator tests:
  - `test/cerberus/public_api_test.exs`
  - `test/cerberus/locator_test.exs`
- Verified compile/tests via direct Elixir execution (sandbox blocks `mix test` in this environment).
