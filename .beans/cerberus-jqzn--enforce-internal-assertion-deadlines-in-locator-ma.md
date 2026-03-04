---
# cerberus-jqzn
title: Enforce internal assertion deadlines in locator matcher hot paths
status: completed
type: bug
priority: normal
created_at: 2026-03-04T21:44:20Z
updated_at: 2026-03-04T21:51:00Z
---

Prevent assert_has/refute_has from running until ExUnit timeout by propagating hard deadlines into HTML locator evaluation loops and surfacing timeout-expired outcomes.

## Summary of Changes
Implemented deadline-aware assertion evaluation for non-browser timeout flows and reduced composed-locator hotspot cost.
- Added monotonic assertion deadline propagation through Cerberus.Phoenix.LiveViewTimeout (stored/restored per-process during timed actions).
- Added cooperative deadline checks in Cerberus.Html locator matcher hot paths and throw sentinel when deadline is exceeded.
- Updated live/static locator assertion execution to convert deadline-exceeded throws into a clear assertion failure reason instead of hanging until ExUnit timeout.
- Optimized composed and_ locator matching by removing redundant seed CSS member checks and by caching hidden-node scans per root during assertion value extraction.
- Verified with targeted Cerberus tests, slow locator parity corpus test, and EV2 job_titles_live/index_test (line-specific and full file).
