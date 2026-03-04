---
# cerberus-pxmk
title: Add aria-label locator
status: completed
type: feature
priority: normal
created_at: 2026-03-02T20:04:54Z
updated_at: 2026-03-04T07:57:48Z
---

Goal: add first-class aria-label locator support to Cerberus locator APIs.\n\nScope:\n- [x] Define aria-label locator semantics and naming in public API\n- [x] Implement aria-label matching across static, live, and browser drivers\n- [x] Add locator helper and sigil support if applicable\n- [x] Add parity tests under test/cerberus\n- [x] Update docs and examples

## Summary of Changes

- Added first-class aria_label locator helper support (aria_label/1..3) and sigil modifier a (~l"..."a).
- Implemented aria_label matching in static, live, and browser drivers (action + assertion paths).
- Added/updated parity tests and locator normalization/sigil tests.
- Updated docs/examples in README.md, docs/getting-started.md, and docs/cheatsheet.md.
