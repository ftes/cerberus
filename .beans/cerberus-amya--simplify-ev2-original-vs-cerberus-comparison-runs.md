---
# cerberus-amya
title: Simplify EV2 original vs Cerberus comparison runs
status: completed
type: task
priority: normal
created_at: 2026-03-11T14:20:19Z
updated_at: 2026-03-11T17:21:45Z
---

Add a simple, reproducible way to run only preserved original counterpart tests and only preserved *_cerberus_test.exs files in /Users/ftes/src/ev2-copy for runtime comparison, avoiding unrelated tagged tests and cross-lane contamination.

## 2026-03-11 Sequential compare run\n\n- Added dedicated compare-only tags in /Users/ftes/src/ev2-copy so preserved originals and preserved *_cerberus_test.exs files can be run without file lists.\n- Added Mix aliases in /Users/ftes/src/ev2-copy/mix.exs:\n  - mix test.cerberus.compare.original\n  - mix test.cerberus.compare.copy\n- Verified originals remain unchanged except for added tags.\n- Sequential runs showed the aliases are wired correctly, but neither lane is fully green under broad suite load yet.\n- Original lane result: 866 tests, 1 failure, 25 skipped, Finished in 58.4 seconds. Failure was in Features.ConstructionRatesTest with DB/sandbox ownership noise.\n- Cerberus copy lane result: 731 tests, 56 failures, 32 skipped, Finished in 111.3 seconds. Failures are dominated by Cerberus browser runtime / suite-load instability in heavy browser files (for example construction_rates_cerberus_test, create_offer_cerberus_test, inactivity_logout_cerberus_test, document_controller_cerberus_test).\n- Conclusion: the compare-tag simplification is good and should stay, but current broad runtime comparison is not yet trustworthy because the Cerberus copy lane is not stable under this broad load.

\n## 2026-03-11 CI follow-up\n\n- Run compare original and compare copy lanes sequentially in EV2 CI regardless of the integration-tests PR label.\n- Ensure CI installs the dependencies those lanes need: assets node_modules for Playwright supervisor startup and Cerberus Chrome binaries for browser-copy tests.\n- Keep the existing integration-tests label gate only for the broader Playwright integration lane; comparison lanes should be unconditional.\n

## Summary of Changes
- Added always-on compare lane steps to /Users/ftes/src/ev2-copy/.github/workflows/ci.yml so the preserved original and Cerberus copy lanes run sequentially in CI regardless of the integration-tests PR label.
- Installed compare-lane prerequisites unconditionally in the test job: mix assets.install for Playwright-supervisor startup and MIX_ENV=test mix cerberus.install.chrome for Cerberus browser-copy tests.
- Kept the existing integration-tests label gate only for the broader integration lane; compare lanes now use the dedicated mix aliases already added to /Users/ftes/src/ev2-copy/mix.exs.
