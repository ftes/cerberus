---
# cerberus-u4b8
title: Check EV2 Firefox DB failures for standalone behavior
status: completed
type: task
priority: normal
created_at: 2026-03-12T16:38:57Z
updated_at: 2026-03-12T16:45:10Z
---

Run the three Firefox-backed `Features.SetContractTypeOnOfferCreationCerberusTest` failures from the EV2 Cerberus suite standalone, determine whether they pass in isolation, and if they do rerun the full Firefox Cerberus suite to compare.

- [x] run the failing SetContractTypeOnOfferCreationCerberusTest cases standalone
- [x] if standalone passes, rerun the full EV2 Cerberus Firefox suite
- [x] summarize whether the failures are standalone or concurrency-related

## Summary of Changes

- Re-ran the previously failing `Features.SetContractTypeOnOfferCreationCerberusTest` cases in isolation with `mix test --only cerberus --failed test/features/set_contract_type_on_offer_creation_cerberus_test.exs --max-cases 1`: 2 tests, 0 failures.
- Re-ran the full `test/features/set_contract_type_on_offer_creation_cerberus_test.exs` file in isolation under Firefox: 33 tests, 0 failures, 1 skipped.
- Re-ran the full EV2 Cerberus Firefox suite with `mix test --only cerberus --max-cases 14`: 689 tests, 1 failure, 30 skipped, 5042 excluded, finished in 275.9s.
- The earlier DB-side failures did not reproduce on the full rerun, which strongly suggests they were suite-load or contention related rather than deterministic standalone failures.
- Re-ran the remaining failed case with `--failed`: `Features.GenerateTimecardsBrowserCerberusTest` still fails standalone with `within/3 failed: no elements matched within locator` for `#project-section`, so the current blocker is a reproducible browser flow issue, not the earlier DB contention.
