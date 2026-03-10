---
# cerberus-wrpd
title: Verify EV2 migrated Cerberus tests after dialog removal
status: completed
type: task
priority: normal
created_at: 2026-03-09T17:48:28Z
updated_at: 2026-03-09T17:52:24Z
---

Run the migrated EV2 Cerberus-tagged test subset against the current Cerberus HEAD after removing browser dialog support, capture failures if any, and summarize whether downstream migrations still work.

## Summary of Changes

- Fetched the new downstream Hex deps in ../ev2-copy so the app could compile against Cerberus after the bibbidi addition.
- Ran the migrated EV2 Cerberus-tagged subset with browser tests included: PORT=4877 MIX_ENV=test mix test --only cerbrerus --include integration.
- Result was not green under full-suite load: 279 tests, 5 failures, 6 skipped. A rerun of the failed subset passed cleanly: PORT=4878 MIX_ENV=test mix test --only cerbrerus --include integration --failed => 5 tests, 0 failures.
- The observed failures were suite-only flakes, not dialog-support regressions. The first surfaced issues were the existing public notifications live assertion timeout, a live assertion deadline failure in dates_test, and recurring EV2 sandbox ownership / owner-exit failures in browser-backed flows.
