---
# cerberus-wyze
title: Locator helper parity slice
status: todo
type: task
created_at: 2026-02-27T11:01:04Z
updated_at: 2026-02-27T11:01:04Z
parent: cerberus-zqpu
blocked_by:
    - cerberus-vb0e
---

## Scope
Expand locator ergonomics using PhoenixTest.Playwright selector helper concepts, after basic sigils land.

## Capability Group
- helper constructors for common selector intents (text, role, label, link, button, testid)
- composition/option helpers where appropriate (exact, visible, normalization, role name)
- normalization into the existing Cerberus locator model

## Notes
- This is additive and should not break existing string/regex/[text: ...] locators.
- Keep one unified locator normalization path across all drivers.

## Done When
- [ ] Helper-based locators and legacy locators are behaviorally equivalent for shared cases.
- [ ] Public docs show ergonomic patterns for both minimal and explicit selector styles.
- [ ] At least one conformance scenario uses helper-based locators.
