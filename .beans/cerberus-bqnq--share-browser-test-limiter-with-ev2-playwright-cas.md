---
# cerberus-bqnq
title: Share browser test limiter with EV2 Playwright case
status: in-progress
type: bug
priority: normal
created_at: 2026-03-11T20:15:56Z
updated_at: 2026-03-11T20:20:21Z
---

The EV2 original Playwright browser suite still runs outside the Cerberus browser test limiter, which can leave CI with too many concurrent browser-backed modules and intermittent 4s action timeouts.

- [x] inspect EV2 PlaywrightCase setup_all path and confirm it does not use the limiter
- [x] wire PlaywrightCase to use the shared Cerberus browser concurrency limiter
- [x] run focused EV2 browser tests with random PORT
- [x] summarize changes and mark bean completed if all work is done

## Summary of Changes

Wired Ev2Web.PlaywrightCase setup_all through Cerberus.Browser.limit_concurrent_tests/0 so original Playwright browser modules share the same concurrency cap as Cerberus browser modules.

Validation:
- PORT=4324 mix test test/features/generate_timecards_browser_test.exs --include integration


Note: EV2 compare aliases were including :integration additively, so compare.copy was unintentionally picking up PlaywrightCase modules. Fixing aliases to rely on --only alone.
