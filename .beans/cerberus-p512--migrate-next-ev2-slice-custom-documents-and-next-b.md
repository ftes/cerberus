---
# cerberus-p512
title: 'Migrate next EV2 slice: custom documents and next browser pair'
status: completed
type: task
priority: normal
created_at: 2026-03-07T05:50:25Z
updated_at: 2026-03-07T06:21:42Z
---

## Scope

- [x] Migrate test/features/custom_documents_test.exs from PhoenixTest to Cerberus using ConnCase.
- [x] Migrate one additional browser slice from Playwright to Cerberus using UI login and browser sandbox metadata.
- [x] Keep structured locators and tag migrated coverage with :cerbrerus.
- [x] Run targeted MIX_ENV=test verification in ../ev2-copy with random PORT values.

## Notes

Prefer the least awkward browser slice after reading the candidate files.

## Summary of Changes

Migrated test/features/custom_documents_test.exs to Cerberus on ConnCase and test/features/construction_rates_test.exs to Cerberus browser sessions with UI login plus Browser.user_agent_for_sandbox metadata.

Fixed migration-specific issues along the way: the custom document flow needed the correct custom document route and button text, the offer acceptance step was handled via a direct ConnCase PUT on the server-side response action, and the construction rates browser assertion needed to verify the saved rate on the offer details page rather than assuming a schedule redirect.

Verification:
- cd /Users/ftes/src/ev2-copy && eval $(direnv export zsh) && PORT=5021 MIX_ENV=test mix test test/features/custom_documents_test.exs test/features/construction_rates_test.exs --include integration
- Result: 3 tests, 0 failures
