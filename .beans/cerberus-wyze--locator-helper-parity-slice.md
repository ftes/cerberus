---
# cerberus-wyze
title: Locator helper parity slice
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:01:04Z
updated_at: 2026-02-27T17:31:45Z
parent: cerberus-zqpu
blocked_by:
    - cerberus-vb0e
---

## Scope
Expand locator ergonomics using PhoenixTest.Playwright selector helper concepts, after basic sigils land.

## Capability Group
- helper constructors for common selector intents (`text`, `role`, `label`, `link`, `button`, `testid`)
- composition/option helpers where appropriate (`exact`, `visible`, `normalize_ws`, role `name`)
- normalization into the existing Cerberus locator model

## Notes
- This is additive and does not break existing string/regex/[text: ...] locators.
- Locator normalization remains unified across drivers.
- `testid/1` is available as a helper, but operations intentionally raise explicit unsupported errors in this slice.

## Done When
- [x] Helper-based locators and legacy locators are behaviorally equivalent for shared cases.
- [x] Public docs show ergonomic patterns for both minimal and explicit selector styles.
- [x] At least one conformance scenario uses helper-based locators.

## Summary of Changes
- Added helper locator constructors in `Cerberus`: `text/1`, `role/2`, `label/1`, `link/1`, `button/1`, `testid/1`.
- Extended `Locator.normalize/1` to support helper locator shapes and role->kind coercion (`:button`, `:link`, and textbox-like roles to `:label`).
- Updated assertion operation normalization so helper locators route through existing driver behavior without duplicating driver logic.
- Added explicit unsupported errors for `testid` operations in this slice.
- Added/updated tests to cover helper normalization and end-to-end helper flows.
- Updated README with helper locator API and usage examples.
