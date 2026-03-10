---
# cerberus-fwb3
title: Restore exhaustive locator parity and measure speedup
status: completed
type: task
priority: normal
created_at: 2026-03-10T17:12:06Z
updated_at: 2026-03-10T17:14:42Z
---

## Goal

Restore exhaustive locator parity coverage, keep the harness improvements that speed it up, and measure runtime before vs after for the locator parity module.

## Todo

- [x] Restore exhaustive locator parity coverage
- [x] Keep the shared session/CDP evaluate improvements
- [x] Measure baseline runtime for the old module shape
- [x] Measure improved runtime for the restored module
- [x] Summarize the speedup and complete the bean

## Summary of Changes

Restored the exhaustive locator parity module in `test/cerberus/locator_parity_test.exs`, including all five original exhaustive tests, while keeping the harness improvements: `SharedBrowserSession.start!/1` and `use_cdp_evaluate: true` for the parity module browser session.

Measured the old module shape using a temporary baseline copy of the original file (`session(:browser)` without explicit CDP evaluate) and compared it to the restored module with the shared-session/CDP-evaluate improvements. Warm-cache timed runs with `/usr/bin/time -p mix test ...` were:

- baseline: `real 16.21`, ExUnit `15.3s`
- improved: `real 12.74`, ExUnit `11.9s`

That is about `3.47s` faster wall-clock, or roughly `21.4%` faster for this module.

Final verification: `source .envrc && PORT=4644 mix test test/cerberus/locator_parity_test.exs` passed with 5 tests and 0 failures in about 11.8 seconds.
