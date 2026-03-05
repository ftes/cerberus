---
# cerberus-asrm
title: Remove bare string locator inputs and enforce explicit select option locators
status: in-progress
type: feature
created_at: 2026-03-04T21:36:07Z
updated_at: 2026-03-04T21:36:07Z
---

## Goal
Remove ambiguous bare string locators from Cerberus public APIs. Require explicit locator values for all locator params and require text locators for select option argument.

## Tasks
- [ ] Audit public API and assertions that currently accept bare strings as locator inputs
- [ ] Remove bare string acceptance paths and tighten types/specs/contracts
- [ ] Require select option argument to be a text locator input (not bare string)
- [ ] Update tests/docs/examples to use explicit locators, preferring sigils for simple text/css cases
- [ ] Run focused regression suite and verify ev2 failing case behavior
