---
# cerberus-qsr2
title: 'Clean cut: label sigil, locator-type narrowing, and docs/test migration'
status: in-progress
type: feature
created_at: 2026-03-06T10:37:13Z
updated_at: 2026-03-06T10:37:13Z
---

## Goal
Implement clean-cut locator API changes:
1) Add label sigil modifier.
2) Migrate tests from label helper and text keyword locator literals to sigils where possible.
3) Remove literal map and keyword locator support and simplify locator normalization/driver paths accordingly.
4) Replace broad locator input aliases with Locator.t() in public and internal specs.
5) Update docs to use label sigils and refresh top README flow with login fill and submit before assert.

## Todo
- [ ] Add l sigil modifier for label locators with parser and tests
- [ ] Remove locator literal map and keyword normalization support
- [ ] Narrow action and assertion APIs to Locator.t() inputs
- [ ] Migrate tests from label helper and text keyword literals to sigils
- [ ] Simplify resolver paths that depended on literal locator normalization
- [ ] Update README and docs for label sigil usage and login flow example
- [ ] Run mix format
- [ ] Run targeted tests frequently with source .envrc and random PORT in 4xxx
- [ ] Run mix do format + precommit + test + test --only slow
