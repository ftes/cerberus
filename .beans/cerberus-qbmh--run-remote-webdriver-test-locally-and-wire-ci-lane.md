---
# cerberus-qbmh
title: Run remote webdriver test locally and wire CI lane
status: completed
type: task
priority: normal
created_at: 2026-02-28T18:04:43Z
updated_at: 2026-02-28T19:33:23Z
---

Validate the new remote webdriver test with local Docker and add CI coverage for it.

## Acceptance Criteria
- [x] Local run of remote webdriver integration test succeeds when Docker is available.
- [x] CI workflow includes an explicit lane for remote webdriver integration test.
- [x] Changes are pushed and CI result is verified.

## Summary of Changes
- Added global mix test.websocket task that starts a Selenium container, waits for /status, sets WEBDRIVER_URL and host wiring, runs mix test, and cleans up.
- Added remote webdriver integration coverage in test/core/remote_webdriver_behavior_test.exs with runtime reset and cleanup, plus support for externally supplied WEBDRIVER_URL.
- Updated browser runtime session parsing to normalize private capabilities.webSocketUrl hosts to the configured WebDriver service host/port.
- Added runtime unit tests for websocket URL normalization behavior.
- Pushed commit 5ee2130 and verified CI run 22527402736. The workflow failed in migration verification before browser lanes due missing migration fixture test files.
