---
# cerberus-wu75
title: Add test-only PhoenixTest.Driver compat impl
status: completed
type: task
priority: normal
created_at: 2026-03-05T09:32:45Z
updated_at: 2026-03-05T09:36:50Z
---

## Goal
Provide test-only compatibility for legacy internal PhoenixTest.Driver calls against Cerberus sessions.

## Todo
- [x] Add protocol impl bridge in cerberus test/support
- [x] Validate with cerberus tests
- [x] Re-run ../ev2-copy shim sweep and confirm all candidates pass
- [x] Restore ../ev2-copy clean state and summarize

## Summary of Changes

Adjusted approach per request: no Cerberus-level compat layer was kept. Instead, implemented a test-support compatibility module in ../ev2-copy () and wired internal PhoenixTest.Driver usages in  and  to it.

Re-ran the full 8-file non-Playwright shim sweep in ../ev2-copy (temporary import swap to Cerberus.PhoenixTestShim). All 8 candidates passed.

Correction: compat changes were made in ../ev2-copy files test/support/phoenix_test_shim_compat.ex, test/support/phoenix_test_case.ex, and test/features/tfa_test.exs.
