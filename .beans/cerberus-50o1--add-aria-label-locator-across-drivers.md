---
# cerberus-50o1
title: Add aria-label locator across drivers
status: completed
type: feature
priority: normal
created_at: 2026-03-04T07:40:38Z
updated_at: 2026-03-04T07:54:35Z
---

Add first-class `aria_label` locator input and matching across static/live/browser, with parity tests and docs updates.

- [x] Add locator type + helpers/sigil parsing support
- [x] Implement static/live/browser matching behavior
- [x] Add parity tests
- [x] Run format + precommit

## Summary of Changes

- Added `aria_label/1..3` helper API, locator normalization support, and sigil modifier `a` (`~l"..."a`).
- Threaded `aria_label` matching through static HTML matching, live clickable matching, browser action helpers, and browser assertion helpers.
- Added fixture `aria-label` attributes and parity coverage in `helper_locator_behavior_test.exs`, plus normalization/sigil tests in `locator_test.exs`.
- Updated docs (`README.md`, `docs/getting-started.md`, `docs/cheatsheet.md`) to document the new locator and sigil modifier.
