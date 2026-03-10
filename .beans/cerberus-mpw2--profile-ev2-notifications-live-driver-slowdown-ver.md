---
# cerberus-mpw2
title: Profile EV2 notifications live-driver slowdown versus PhoenixTest
status: completed
type: task
priority: normal
created_at: 2026-03-09T18:54:38Z
updated_at: 2026-03-09T19:01:17Z
---

Use the preserved notifications_test and notifications_cerberus_test pair in EV2 to profile where Cerberus live-driver time is going. Reuse existing Cerberus profiling hooks first, add narrow instrumentation only if needed, and summarize the exact hotspots compared with PhoenixTest's simpler path.

## Summary of Changes

Ran the preserved EV2 notifications_cerberus_test with CERBERUS_PROFILE enabled and compared it against the preserved PhoenixTest notifications_test runtime. Added narrow temporary profiling inside the Cerberus live driver to split live-action time into document refresh, form/button lookup, actionability waiting, render_change or render_click, and rendered-result application, then removed that temporary instrumentation after measuring.

Findings:
- Cerberus notifications_cerberus_test ran in 14.0s for 18 tests; the preserved PhoenixTest notifications_test ran in 2.4s for the same 18 tests.
- The slowdown is not in assertions. assert_has buckets are small compared with live actions.
- The slowdown is not in LiveView render_change or render_click themselves. Narrow profiling showed the expensive part is before the render call: wait_for_live_actionable and the field or button lookup path.
- The dominant hot buckets were wait_for_live_actionable, wait_for_live_form_field, find_form_field, and the live check, uncheck, fill_in, and click driver operations that wrap them.
- In the worst Cerberus notifications tests, repeated field lookup plus actionability waiting consumed hundreds of milliseconds per action, while render_form_phx_change was only about 11.7ms average in the heaviest test.
- PhoenixTest is faster here because its live driver is much thinner: it delegates more directly to render_change, render_click, and render_submit with less pre-action document refresh and locator or actionability work.

No permanent code changes were kept in Cerberus for this profiling pass.
