---
# cerberus-vb0e
title: Add locator sigils for ergonomic selectors
status: completed
type: task
priority: normal
created_at: 2026-02-27T08:07:45Z
updated_at: 2026-02-27T16:27:34Z
parent: cerberus-ktki
---

## Scope
Add first-class locator sigils to complement map/keyword locators and improve API ergonomics.

## Initial Goal
- Support text-first sigils that normalize into existing locator structures.
- Keep semantics identical to current `Locator.normalize/1` behavior.
- Do not introduce a separate DSL layer.

## Proposed API
- `~l"Save"` / `~t"Save"` -> `%Locator{kind: :text, value: "Save"}`
- `~L/Save\s+changes/i` -> `%Locator{kind: :text, value: ~r/Save\s+changes/i}`

## Design Constraints
- Sigils should compile to existing locator format with zero behavior drift.
- Error messages must remain consistent with non-sigil locators.
- Pipe usage remains `session |> click(~l"Save")` style.

## Tests
- [x] sigil locators work with `assert_has`, `refute_has`, and `click`.
- [x] sigil and non-sigil locators produce identical matching behavior.
- [x] invalid sigil content raises explicit locator errors.

## Done When
- [x] docs include sigil usage examples.
- [x] conformance scenarios include at least one sigil case.

## Summary of Changes
- Added locator sigils in `Cerberus`: `~l` and `~t` for text locators, and `~L` for regex locators.
- Added `Locator.text_sigil/1` and `Locator.regex_sigil/3` to normalize sigil output and raise explicit `InvalidLocatorError` on invalid modifiers/regex.
- Added sigil-focused tests in `test/cerberus/locator_test.exs` and API acceptance in `test/cerberus/public_api_test.exs`.
- Updated core conformance example flow (`test/core/api_examples_test.exs`) to exercise sigils in static/live/browser paths.
- Documented sigil usage in README.
