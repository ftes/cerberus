---
# cerberus-asrm
title: Remove bare string locator inputs and enforce explicit select option locators
status: completed
type: feature
priority: normal
created_at: 2026-03-04T21:36:07Z
updated_at: 2026-03-06T20:17:29Z
---

## Goal
Remove ambiguous bare string locators from Cerberus public APIs. Require explicit locator values for all locator params and require text locators for select option argument.

## Tasks
- [x] Audit public API and assertions that currently accept bare strings as locator inputs
- [x] Remove bare string acceptance paths and tighten types/specs/contracts
- [x] Require select option argument to be a text locator input (not bare string)
- [x] Update tests/docs/examples to use explicit locators, preferring sigils for simple text/css cases
- [x] Run focused regression suite and verify ev2 failing case behavior

## Summary of Changes
- Removed bare string and regex locator shorthand from the public API surface in favor of explicit locators.
- Enforced text-locator-only select option inputs, updated docs and examples, and verified focused regression coverage.
