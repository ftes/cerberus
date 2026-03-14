---
# cerberus-rtta
title: Fix profiling JSON export for tuple buckets
status: completed
type: bug
priority: normal
created_at: 2026-03-13T08:31:50Z
updated_at: 2026-03-13T08:33:19Z
---

Profiling artifact export crashes when bucket or context values are tuples, which happens in real browser-profile runs. Normalize snapshot payloads to JSON-safe shapes and add coverage for tuple buckets.

- [x] normalize tuple-heavy snapshot rows to JSON-safe values
- [x] extend profiling export coverage to tuple bucket/context rows
- [x] rerun focused profiling verification

## Summary of Changes

- Normalized profiling snapshot payloads before JSON encoding so tuple-heavy bucket and context values are exported as nested JSON arrays instead of crashing the encoder.
- Removed the stale unused profiling compile-time attribute while touching the export path.
- Extended profiling tests to cover tuple bucket and tuple context export.
- Verified with PORT=4453 CERBERUS_PROFILE_COMPILE=1 mix test test/cerberus/profiling_test.exs and a real profiled browser smoke run writing artifacts to tmp/profile-smoke.
