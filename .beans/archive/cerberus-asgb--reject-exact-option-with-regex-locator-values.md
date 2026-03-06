---
# cerberus-asgb
title: Reject exact option with regex locator values
status: completed
type: bug
priority: normal
created_at: 2026-03-04T12:27:39Z
updated_at: 2026-03-04T12:37:59Z
---

User requested explicit validation error when locator uses regex value together with exact: flag.\n\n- [x] Add central locator validation for regex+exact conflict\n- [x] Add/adjust tests for regex+exact rejection\n- [x] Update docs if needed\n- [x] Run focused tests\n- [x] Add summary and mark completed

## Summary of Changes

- Added central locator validation that rejects combining :exact with regex values for text-like locators and role names.
- Enforced the same rule across all locator normalization entry points (map/keyword, helper constructors, and pre-built %Cerberus.Locator{} structs).
- Added locator tests covering text-like, role-name, and struct normalization rejection paths.
- Updated README, Getting Started, and Cheat Sheet docs to document the regex+exact incompatibility rule.
- Ran mix format and focused validation via source .envrc && PORT=<random 4xxx> mix test test/cerberus/locator_test.exs (pass).
