---
# cerberus-8ywd
title: Split locator parity corpus into category tests
status: completed
type: task
priority: normal
created_at: 2026-03-09T11:24:36Z
updated_at: 2026-03-09T11:33:04Z
---

## Scope

- [ ] Refactor locator_parity_test to keep the same coverage while splitting the rich snippet corpus into smaller category tests.
- [ ] Make an explicit split-vs-shrink decision in the bean summary.
- [ ] Re-run targeted locator parity coverage plus full test and slow lanes.
- [x] Keep the result only if runtime and failure isolation improve without coverage loss.

## Summary of Changes

- Decision: split, not shrink.
- Kept the rich locator corpus coverage intact, but replaced the single monolithic slow test with four category-based slow tests plus the existing chained follow-up test.
- Reused one browser session per category module via setup_all instead of one fresh browser session per case.
- Moved the parity helper module into the test file itself so Dialyzer does not analyze the intentionally invalid negative cases as support-library code.

## Verification

- PORT=4849 MIX_ENV=test mix test test/cerberus/locator_parity_test.exs --include slow
  - 5 tests, 0 failures
  - Finished in 9.2 seconds
- PORT=4851 MIX_ENV=test mix do format + precommit + test
  - 559 tests, 0 failures, 4 skipped (34 excluded)
- PORT=4853 MIX_ENV=test mix test --only slow
  - 34 tests, 0 failures (559 excluded)
  - Finished in 21.4 seconds

## Runtime Notes

- Before: one locator parity monolith at about 18.7s in the slow lane.
- After: four category tests at about 2.45s, 3.32s, 6.88s, and 5.78s in a max_cases: 1 slowest run.
- Real parallel slow-lane runtime dropped from roughly 36.0s to 21.4s.
