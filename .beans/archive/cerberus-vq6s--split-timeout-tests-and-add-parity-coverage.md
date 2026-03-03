---
# cerberus-vq6s
title: Split timeout tests and add parity coverage
status: completed
type: task
priority: normal
created_at: 2026-03-03T22:10:23Z
updated_at: 2026-03-03T22:12:36Z
---

Split live timeout tests into live-driver internals vs cross-driver behavior, and add browser parity coverage for live visibility, static upload, and static navigation tests.

## Summary of Changes

- Split timeout coverage by intent: retained live-driver timeout internals in live_timeout_assertions_test.exs and added cross-driver timeout behavior parity in timeout_behavior_parity_test.exs.
- Added browser parity loops for live visibility filters, static upload testid flow, and static navigation/redirect scenarios using SharedBrowserSession.
- Adjusted static upload parity assertion to validate shared behavior marker text across drivers.
- Verified with targeted suite run over the five updated test files (18 tests, 0 failures).
