---
# cerberus-37lt
title: Run precommit and full test suite
status: completed
type: task
priority: normal
created_at: 2026-03-06T10:46:22Z
updated_at: 2026-03-06T10:49:57Z
---

## Goal
Execute precommit and all tests on current branch.

## Todo
- [x] Run mix precommit with envrc
- [x] Run full regular test suite
- [x] Run slow test suite
- [x] Report results

## Summary of Changes
- Ran source .envrc and mix precommit.
  - Result: failed (Credo readability) at lib/cerberus/locator.ex:194 with line length 125 > 120.
- Ran source .envrc and PORT=4234 mix test.
  - Result: failed with 561 tests, 218 failures, 2 skipped (1 excluded).
  - Primary failure pattern: Cerberus.InvalidLocatorError from locator normalization (invalid locator [role: ...] and [text: ...]).
- Ran source .envrc and PORT=4238 mix test --only slow.
  - Result: failed with 1 test, 1 failure (locator parity suite), same locator normalization error pattern.
