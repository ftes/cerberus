---
# cerberus-hpzf
title: Flatten test layout and rename locator parity module
status: completed
type: task
priority: normal
created_at: 2026-03-01T20:33:58Z
updated_at: 2026-03-01T20:36:28Z
---

Move tests out of test/cerberus/core into test/cerberus root and rename locator oracle harness to Cerberus.LocatorParityTest under test/cerberus. Keep module/file naming aligned with module under test and avoid conflicts with Cerberus.LocatorTest.


## Todo
- [x] Rename locator oracle harness file/module to LocatorParityTest in test/cerberus
- [x] Move core tests from test/cerberus/core into test/cerberus
- [x] Remove now-empty test/cerberus/core directory
- [x] Run format and focused tests
- [x] Commit code + bean file

## Summary of Changes
- Renamed locator parity harness to `test/cerberus/locator_parity_test.exs` and renamed module to `Cerberus.LocatorParityTest`.
- Moved `OptionsTest` and `QueryTest` from `test/cerberus/core/` to `test/cerberus/` to keep tests flat under `test/cerberus`.
- Removed the now-empty `test/cerberus/core` directory.
- Ran `mix format` and focused warning-as-error tests for moved/renamed files.
- `mix precommit` still reports the existing dialyzer warnings in `lib/cerberus/driver/browser/extensions.ex` (unchanged from prior runs).
