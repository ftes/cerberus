---
# cerberus-828k
title: Move test concurrency limit into config
status: completed
type: task
priority: normal
created_at: 2026-03-15T06:50:44Z
updated_at: 2026-03-15T07:15:16Z
---

Remove the hardcoded ExUnit max_cases override, configure max_concurrent_tests in config/test.exs as half the schedulers, and wire browser test startup through explicit test helpers so browser concurrency is lower in CI without forcing 28 for everything.

## Summary of Changes
- removed the hardcoded ExUnit max_cases override from test/test_helper.exs so non-browser tests can use normal ExUnit concurrency again
- configured `config :cerberus, :browser, max_concurrent_tests` in test config to default to `max(div(System.schedulers_online(), 2), 1)`
- restored the explicit public `Cerberus.Browser.limit_concurrent_tests/1` API and removed the hidden automatic limiter from `Driver.Browser.new_session/1`
- added test-support helpers for explicit browser throttling: direct browser session helpers in `Cerberus.TestSupport.BrowserSessions` and shared-session coverage in `Cerberus.TestSupport.SharedBrowserSession`
- updated the affected browser tests and docs to use the explicit helper pattern instead of relying on hidden runtime behavior
- verified the focused browser/concurrency slice and the full precommit gate pass locally
