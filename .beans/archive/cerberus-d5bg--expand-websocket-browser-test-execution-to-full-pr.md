---
# cerberus-d5bg
title: Expand websocket browser test execution to full practical suite
status: completed
type: task
priority: normal
created_at: 2026-02-28T19:45:18Z
updated_at: 2026-02-28T19:55:01Z
---

## Goal
Run the websocket browser path against as much of the test suite as practical (matching ../ptp intent), including a clear strategy for Chrome/Firefox.

## Todo
- [x] Audit current websocket/browser test lanes and exclusions
- [x] Implement runner/config changes for broader websocket coverage
- [x] Validate with focused and/or full-suite runs (chrome/firefox where feasible)
- [x] Update docs if commands or behavior changed
- [x] Summarize changes and mark bean complete

## Summary of Changes
- Extended mix test.websocket with a --browsers flag supporting chrome, firefox, and all.
- Added browser list fallback via CERBERUS_REMOTE_SELENIUM_BROWSERS.
- Added per-browser Selenium image overrides via CERBERUS_REMOTE_SELENIUM_IMAGE_CHROME and CERBERUS_REMOTE_SELENIUM_IMAGE_FIREFOX, with shared fallback CERBERUS_REMOTE_SELENIUM_IMAGE.
- Updated websocket task execution to run mix test in a subprocess per browser pass with environment wiring for CERBERUS_BROWSER_NAME, WEBDRIVER_URL, CERBERUS_BASE_URL_HOST, and CERBERUS_REMOTE_WEBDRIVER.
- Hardened Docker container-id parsing in test.websocket to tolerate pull/progress output.
- Added CERBERUS_BROWSER_NAME parsing to config/test.exs so the default browser lane can be switched per invocation.
- Updated CI websocket lane to run mix test.websocket --browsers chrome,firefox.
- Updated README and docs/getting-started.md with websocket multi-browser usage.

## Validation
- mix format
- mix test test/cerberus/harness_test.exs test/cerberus/driver/browser/runtime_test.exs
- mix test.websocket --browsers chrome,firefox --only remote_webdriver
- mix test.websocket --browsers chrome,firefox test/core/browser_tag_showcase_test.exs
