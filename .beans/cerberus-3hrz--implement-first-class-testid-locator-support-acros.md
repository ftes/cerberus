---
# cerberus-3hrz
title: Implement first-class testid locator support across drivers
status: todo
type: feature
created_at: 2026-02-28T17:53:45Z
updated_at: 2026-02-28T17:53:45Z
---

Current state: Locator supports :testid normalization, but core operations intentionally raise "testid locators are not yet supported".

Scope:
- Add data-testid selector support for click, fill_in, upload, select/choose/check/uncheck, submit, assert_has, and refute_has.
- Keep behavior consistent across static, live, and browser drivers where operation semantics are available.
- Add conformance coverage and user-facing docs updates for testid helper behavior.

Acceptance:
- testid("...") works for supported operations without raising unsupported errors.
- Cross-driver tests pass and document any intentional driver-specific limits.
