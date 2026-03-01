---
# cerberus-3hrz
title: Implement first-class testid locator support across drivers
status: completed
type: feature
priority: normal
created_at: 2026-02-28T17:53:45Z
updated_at: 2026-03-01T20:03:55Z
---

Current state: Locator supports :testid normalization, but core operations intentionally raise "testid locators are not yet supported".

Scope:
- Add data-testid selector support for click, fill_in, upload, select/choose/check/uncheck, submit, assert_has, and refute_has.
- Keep behavior consistent across static, live, and browser drivers where operation semantics are available.
- Add conformance coverage and user-facing docs updates for testid helper behavior.

Acceptance:
- testid("...") works for supported operations without raising unsupported errors.
- Cross-driver tests pass and document any intentional driver-specific limits.

## Summary of Changes
- Implemented first-class `testid(...)` support across assertions and core actions in static/live/browser flows where semantics are available.
- Added and normalized `data-testid` fixture coverage for click, fill_in, upload, select/choose/check/uncheck, submit, and assert/refute flows.
- Removed LiveView click/link fallback that depended on LiveViewTest text matching; live click execution now uses selector-based targeting after Cerberus resolves matches.
- Added/expanded cross-driver integration tests under `test/cerberus/cerberus_test/*` to validate `testid` behavior.
- Updated user docs locator constructor lists (`README.md`, `docs/cheatsheet.md`) to include `testid("...")`.
