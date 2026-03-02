---
# cerberus-cwj5
title: Add has(label/relations) + closest composition for wrapper scoping
status: completed
type: feature
priority: normal
created_at: 2026-03-02T11:27:07Z
updated_at: 2026-03-02T11:37:37Z
---

Implement nested has support for label and other sensible locator kinds, add explicit closest semantics for has-matching, and document/test Phoenix phx.new field-wrapper error assertions (including nested fieldset closest behavior).

## TODO
- [x] Extend locator normalization so nested has supports label and other sensible kinds (not just css/text/testid)
- [x] Add explicit closest semantics for has composition and propagate through matching helpers
- [x] Update within/html/browser matching paths to honor closest has behavior consistently
- [x] Add focused tests for Phoenix-style field wrapper error assertions and nested-wrapper closest selection
- [x] Update docs: README example + within docs example for field error wrapper assertions
- [x] Run mix format, targeted tests, and mix precommit

## Summary of Changes
- Added explicit `closest/2` locator composition helper with `from:` nested locator support (`closest(css(".fieldset"), from: label("Email"))`).
- Extended nested locator normalization so `has:` supports label and other helper locator kinds, and added `:from` normalization for closest composition.
- Updated HTML locator matching to support generalized nested `has` matching and closest-ancestor resolution for within scope target selection.
- Added Phoenix fixture route `/field-wrapper-errors` with phx.new-style field wrappers and nested fieldsets.
- Added tests covering `has: label(...)` wrapper scoping and nearest-wrapper selection with `closest(...)`.
- Updated docs in README and guides with field-wrapper error assertion examples using `closest(...)`.
- Ran `mix format`, targeted tests (`locator_test`, `within_closest_behavior_test`), and `mix precommit` with `.envrc` browser paths.
