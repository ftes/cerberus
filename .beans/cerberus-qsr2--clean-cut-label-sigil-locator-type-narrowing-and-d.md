---
# cerberus-qsr2
title: 'Clean cut: label sigil, locator-type narrowing, and docs/test migration'
status: completed
type: feature
priority: normal
created_at: 2026-03-06T10:37:13Z
updated_at: 2026-03-06T13:07:55Z
---

## Goal
Implement clean-cut locator API changes:
1) Add label sigil modifier.
2) Migrate tests from label helper and text keyword locator literals to sigils where possible.
3) Remove literal map and keyword locator support and simplify locator normalization/driver paths accordingly.
4) Replace broad locator input aliases with Locator.t() in public and internal specs.
5) Update docs to use label sigils and refresh top README flow with login fill and submit before assert.

## Todo
- [x] Add l sigil modifier for label locators with parser and tests
- [x] Remove locator literal map and keyword normalization support
- [x] Narrow action and assertion APIs to Locator.t() inputs
- [x] Migrate tests from label helper and text keyword literals to sigils
- [x] Simplify resolver paths that depended on literal locator normalization
- [x] Update README and docs for label sigil usage and login flow example
- [x] Run mix format
- [x] Run targeted tests frequently with source .envrc and random PORT in 4xxx
- [x] Run mix do format + precommit + test + test --only slow

## Notes\n- Ran mix do format + precommit + test + test --only slow with source .envrc and random PORT in 4xxx.\n- format, precommit, and full mix test pass.\n- slow suite fails in this environment because Chrome session startup exits before test execution (webdriver session not created).

## Summary of Changes
- Added label sigil modifier support and parser/tests.
- Removed locator literal map and keyword locator normalization paths.
- Narrowed action/assertion API types to Locator.t() and simplified resolver paths.
- Migrated tests/docs/README examples to sigil-first locator usage and updated login flow example.
- Ran format/precommit/full test and attempted slow suite; slow suite still fails in this environment due Chrome/WebDriver startup before test execution.
