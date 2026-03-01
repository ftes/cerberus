---
# cerberus-g6b6
title: Expand role locator support beyond current subset
status: completed
type: feature
priority: normal
created_at: 2026-02-28T15:08:28Z
updated_at: 2026-03-01T20:07:44Z
---

Feature-gap follow-up: role locator mapping currently supports only a narrow subset.

## Scope
- Prioritize additional ARIA roles with practical test value
- Define normalization rules and error behavior
- Add cross-driver tests for new role coverage

## Acceptance
- role(...) and ~lrole:namer support expanded, documented set

## Summary of Changes
- Expanded role locator normalization with additional practical role aliases: `menuitem`, `tab`, `listbox`, and `spinbutton`.
- Added normalization and sigil coverage in `test/cerberus/locator_test.exs` for the new roles.
- Added cross-driver behavior coverage for new roles:
  - click/assert via `role(:tab, ...)` and `role(:menuitem, ...)`
  - form actions via `role(:listbox, ...)` and `role(:spinbutton, ...)`
- Updated fixture pages/live views to include matching controls for the new role-based flows.
- Extended locator oracle parity corpus with listbox/spinbutton/tab/menuitem role cases.
- Updated docs (`README.md`, `docs/cheatsheet.md`) to document the expanded role alias set.
