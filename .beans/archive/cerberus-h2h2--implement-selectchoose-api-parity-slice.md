---
# cerberus-h2h2
title: Implement select/choose API parity slice
status: completed
type: feature
priority: normal
created_at: 2026-02-28T15:08:28Z
updated_at: 2026-02-28T17:29:28Z
---

Feature-gap follow-up: select/choose form interaction APIs are currently placeholders and not implemented.

## Scope
- Define select/choose semantics across static/live/browser drivers
- Implement APIs and shared validation behavior
- Add conformance tests and docs examples

## Acceptance
- select/choose are functional and documented

## Summary of Changes
- Added first-class `select/3` and `choose/3` APIs with option validation in `Cerberus.Options`, public assertions wiring, and driver callbacks.
- Implemented select/radio behavior in static, live, and browser drivers, including disabled handling, exact option matching, multi-select accumulation semantics, and improved submit default merging.
- Extended HTML form helpers to resolve select option values consistently and to handle default selected values correctly for single vs multi-select fields.
- Added static and live fixtures (`/controls`, `/live/controls`) and conformance tests covering select/choose behavior plus public API validation/error expectations.
- Updated user-facing docs cheatsheet with `select`/`choose` examples and validated the change with `mix format` and `mix precommit`.
