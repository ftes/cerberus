---
# cerberus-q1n2
title: Add context-aware Cerberus profiling for EV2 comparisons
status: completed
type: task
priority: normal
created_at: 2026-03-08T07:17:53Z
updated_at: 2026-03-08T07:22:36Z
---

## Scope

- [x] Add context-aware Cerberus profiling so timings can be attributed to specific tests or files.
- [x] Wire EV2 shared test cases to set profiling context when CERBERUS_PROFILE is enabled.
- [x] Run a targeted slow-file comparison with profiling enabled and capture the top buckets.
- [x] Summarize where the slow Cerberus files are spending time.

## Findings

- Context-aware profiling now groups samples by file and test name, and EV2 shared test cases set that context when CERBERUS_PROFILE is enabled.
- /Users/ftes/src/ev2-copy/test/features/project_form_feature_cerberus_test.exs spent most of its time in browser evaluate_with_timeout, browser click, and browser await_ready. The browser JS buckets were comparatively tiny, so most cost is driver-side waiting and readiness handling rather than DOM execution.
- /Users/ftes/src/ev2-copy/test/features/register_and_accept_offer_cerberus_test.exs showed the same browser profile shape, with evaluate_with_timeout, click, await_ready, and check dominating the run.
- /Users/ftes/src/ev2-copy/test/ev2_web/live/project_settings_live/notifications_cerberus_test.exs had a different shape: live click, check, uncheck, and fill_in dominated, while live assertions were relatively cheap. That points to live action round-trips and enablement waits rather than assertion retries.
