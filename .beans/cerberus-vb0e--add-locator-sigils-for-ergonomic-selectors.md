---
# cerberus-vb0e
title: Add locator sigils for ergonomic selectors
status: todo
type: task
created_at: 2026-02-27T08:07:45Z
updated_at: 2026-02-27T08:07:45Z
parent: cerberus-ktki
---

## Scope
Add first-class locator sigils to complement map/keyword locators and improve API ergonomics.

## Initial Goal
- Support text-first sigils that normalize into existing locator structures.
- Keep semantics identical to current `Locator.normalize/1` behavior.
- Do not introduce a separate DSL layer.

## Proposed API
- `~t"Save"` -> `%Locator{kind: :text, value: "Save"}`
- `~t/Save\s+changes/` -> `%Locator{kind: :text, value: ~r/Save\s+changes/}`

## Design Constraints
- Sigils should compile to existing locator format with zero behavior drift.
- Error messages must remain consistent with non-sigil locators.
- Pipe usage remains `session |> click(~t"Save")` style.

## Tests
- [ ] sigil locators work with `assert_has`, `refute_has`, and `click`.
- [ ] sigil and non-sigil locators produce identical matching behavior.
- [ ] invalid sigil content raises explicit locator errors.

## Done When
- [ ] docs include sigil usage examples.
- [ ] conformance scenarios include at least one sigil case.
