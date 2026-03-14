---
# cerberus-rndu
title: Add CI profiling workflow and artifacts
status: completed
type: task
created_at: 2026-03-13T08:27:13Z
updated_at: 2026-03-13T08:27:13Z
---

Add an opt-in CI workflow that runs the Cerberus test suite with profiling enabled, captures slowest tests in the test logs, and uploads profiling artifacts for later analysis.

- [x] add profiling snapshot export support
- [x] wire profiling report dumping into test shutdown hooks
- [x] add a manual CI profiling workflow with artifacts
- [x] verify focused profiling tests pass

## Summary of Changes

- Added JSON snapshot export support to `Cerberus.Profiling`, writing aggregate bucket and context-bucket files when `CERBERUS_PROFILE_OUTPUT_DIR` is set.
- Updated `test/test_helper.exs` and `test/support/bootstrap.ex` to call `Cerberus.Profiling.dump_reports/1` so CI can get both console summaries and JSON artifacts.
- Added `.github/workflows/ci-profile.yml`, a `workflow_dispatch`-only profiling workflow that runs Chrome and Firefox test suites with `CERBERUS_PROFILE=1`, `CERBERUS_PROFILE_COMPILE=1`, `--slowest 50`, and uploads the artifacts directory.
- Verified with `PORT=4451 mix test test/cerberus/profiling_test.exs`.
