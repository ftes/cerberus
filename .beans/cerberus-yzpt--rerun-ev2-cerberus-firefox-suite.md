---
# cerberus-yzpt
title: Rerun EV2 Cerberus Firefox suite
status: completed
type: task
priority: normal
created_at: 2026-03-12T13:21:31Z
updated_at: 2026-03-12T13:28:07Z
---

Re-run the Firefox-backed Cerberus suite in ../ev2-copy with the correct Cerberus-only scope, capture the actual result after the runtime cleanup and transient retry fixes, and summarize the remaining failures if any.

- [x] identify the correct Cerberus test command in ev2-copy
- [x] run the full Firefox Cerberus suite in ev2-copy
- [x] summarize the result and remaining failures

## Summary of Changes

- Identified that `mix test.cerberus.compare.copy` was broader than the requested scope because it also includes the generic `:integration` lane.
- Re-ran the actual Cerberus suite in `../ev2-copy` with `CERBERUS_BROWSER_NAME=firefox` using `mix test --only cerberus --max-cases 14`.
- Result: 689 tests, 4 failures, 30 skipped, 5042 excluded, finished in 337.0s.
- Remaining failures were not Firefox startup leaks: three failures came from `Features.SetContractTypeOnOfferCreationCerberusTest` due DB connection timeout/closed errors during setup, and one failure came from `Features.RegisterAndAcceptOfferCerberusTest` due `axe.run()` timing out in `Browser.evaluate_js`.
- Verified there were no leftover Firefox processes after the run.
