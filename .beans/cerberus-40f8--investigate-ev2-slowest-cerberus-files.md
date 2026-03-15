---
# cerberus-40f8
title: Investigate EV2 slowest Cerberus files
status: in-progress
type: task
priority: normal
created_at: 2026-03-14T21:21:45Z
updated_at: 2026-03-15T08:15:29Z
---

Use the new EV2 compare harness to take the slowest Cerberus files one by one, form a concrete hypothesis, reproduce the slowdown in Cerberus where possible, fix it, and verify the improvement back in ev2-copy.

## Current slice

- [x] Identify slowest EV2 Cerberus files from the sequential compare harness
- [x] Profile a representative slow test in document_controller_cerberus_test
- [ ] Reproduce the browser submit-button navigation slowdown in Cerberus
- [ ] Simplify browser post-action navigation handling while fixing the slowdown
- [x] Verify the fix in the Cerberus suite and back in ev2-copy

## Progress notes

- Reproduced a browser delayed-submit navigation gap in Cerberus with a focused browser settle test.
- Fixed browser post-action await classification so deferred non-live submit-button clicks get a small grace window before readiness.
- Verified the Cerberus repro and cut EV2 document_controller_cerberus_test from about 107s per file to 19.4s at --max-cases 4.

- Reduced the EV2 project-show live submit hotspot by removing eager live post-submit settle for successful phx-submit flows.
- Cerberus live submit benchmark dropped from about 2181ms to 88ms.
- EV2 admin/pages/projects_live/show_cerberus_test line 18 dropped from about 1.0s to 0.4s; full file now runs in 1.8s at --max-cases 1.

## Progress Notes

Fixed a browser userContext leak in UserContextProcess termination. Previously browser.removeUserContext was skipped whenever the owner test process had already exited, which leaked user contexts across the suite and plausibly destabilized later browser session startup.

Added Cerberus repro coverage in test/cerberus/browser_user_context_cleanup_test.exs. The test spawns a browser session in a child process, waits for owner exit, and asserts the created userContext is removed.

Verification:
- PORT=5121 mix test test/cerberus/browser_user_context_cleanup_test.exs test/cerberus/timeout_defaults_test.exs test/cerberus/playwright_performance_benchmark_test.exs --seed 0 -> 21 tests, 0 failures
- PORT=5123 mix test --seed 616534 -> 643 tests, 0 failures, 2 skipped

- Reproduced a second browser bug in Cerberus where same-path form navigations kept looping in delayed_navigation_still_pending?/2 even after a real navigation completed.
- Added a Cerberus browser repro for same-path submit navigation and fixed Browser.await_action_navigation_ready to stop looping when a real BiDi navigation signal was observed.
- The EV2 my_offer_controller_integration_cerberus test dropped from about 6.4s to 2.5s, with browser await_ready calls falling from 42 to 4.
- Full Cerberus suite is green again at PORT=5180 mix test --seed 616534 (649 tests, 0 failures, 2 skipped).

- Ran a cheap browser-session reset probe in Cerberus using one real browser session on /browser/extensions.
- Within the same session shell, clear_cookies + localStorage.clear + sessionStorage.clear + revisit restored the visible state to match a fresh session.
- Probe timings: new_session about 712ms, reset path about 90ms, fresh session plus visit about 452ms.
- This suggests pooling could help if the remaining browser-side state can be scrubbed safely, but the probe has not yet covered IndexedDB, service workers, permissions, or download/network state.

- Added Cerberus-only startup profiling sub-buckets for browser session creation: browser.createUserContext, init script installation, browsingContext.create, and initial event subscription.
- Added bench/browser_session_startup_breakdown.exs to benchmark fresh browser session startup without EV2 app noise.
- Cerberus-only warm-browser measurement (3 iterations, 1 warmup) showed mean new_session about 350.9ms, with browsingContext.create about 199.7ms, addPreloadScript about 112.4ms, browser.createUserContext about 23.4ms, and session.subscribe about 15.1ms.
- This suggests the biggest fresh-session costs are initial browsing context creation and preload script installation, not browser.createUserContext itself.

- Combined all browser preload scripts into a single script.addPreloadScript call per fresh browser context.
- Cerberus startup benchmark improved: mean fresh new_session about 350.9ms -> 316.9ms; addPreloadScript cost about 112.4ms -> 70.9ms; script.addPreloadScript roundtrips dropped from 2 to 1.
- Warm EV2 construction_rates_cerberus_test did not materially improve (about 10.4s vs about 10.3s before), which indicates the remaining dominant fresh-session cost is browsingContext.create, not preload installation.
- Full Cerberus suite still passes on seed 616534: 650 tests, 0 failures, 2 skipped.
