---
# cerberus-40f8
title: Investigate EV2 slowest Cerberus files
status: in-progress
type: task
priority: normal
created_at: 2026-03-14T21:21:45Z
updated_at: 2026-03-14T22:34:37Z
---

Use the new EV2 compare harness to take the slowest Cerberus files one by one, form a concrete hypothesis, reproduce the slowdown in Cerberus where possible, fix it, and verify the improvement back in ev2-copy.

## Current slice

- [x] Identify slowest EV2 Cerberus files from the sequential compare harness
- [x] Profile a representative slow test in document_controller_cerberus_test
- [ ] Reproduce the browser submit-button navigation slowdown in Cerberus
- [ ] Simplify browser post-action navigation handling while fixing the slowdown
- [ ] Verify the fix in the Cerberus suite and back in ev2-copy

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
