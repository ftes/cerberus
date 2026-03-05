---
# cerberus-k8mr
title: Run EV2 PhoenixTest shim compatibility sweep
status: completed
type: task
priority: normal
created_at: 2026-03-05T08:56:04Z
updated_at: 2026-03-05T09:11:33Z
---

Loop through EV2 tests that import PhoenixTest or use PhoenixTestCase (excluding Playwright tests), switch each candidate to Cerberus.PhoenixTestShim, run each test file, and collect failures.

## Summary of Changes

Executed a one-by-one shim trial in ../ev2-copy for all non-Playwright test files that import PhoenixTest/use PhoenixTestCase. Each file was temporarily rewritten to import Cerberus.PhoenixTestShim, run with MIX_ENV=test and randomized PORT=4xxx, and then restored.

Observed failures across all 8 candidates. Dominant failure mode is redirect to /sessions/new (auth/session not preserved), with one additional protocol mismatch where project helper calls PhoenixTest.Driver.current_path on a Cerberus session.
