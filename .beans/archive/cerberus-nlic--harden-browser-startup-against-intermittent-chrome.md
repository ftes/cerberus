---
# cerberus-nlic
title: Harden browser startup against intermittent Chrome session-creation flakes
status: completed
type: task
priority: deferred
created_at: 2026-03-01T16:13:52Z
updated_at: 2026-03-01T18:07:25Z
---

Track as future improvement only if this flake recurs.

Goal:
- Reduce impact of intermittent webdriver session creation failures where Chrome exits during startup.

Proposed scope when prioritized:
- Add targeted retry for transient session-not-created Chrome startup failures.
- Capture and surface chromedriver verbose logs/artifacts on startup failures.
- Validate behavior in CI under repeated browser session start/stop cycles.

Exit criteria:
- Intermittent startup failures are retried once (or configured) and produce actionable logs when unrecoverable.

## Todo
- [x] Add targeted retry for transient managed Chrome startup session-not-created failures
- [x] Attach ChromeDriver startup log snippets/path to unrecoverable startup errors
- [x] Add runtime tests for retry/error-classification and log formatting helpers
- [x] Validate with repeated Chrome runs for select_choose_behavior

## Summary of Changes
- Added targeted managed-Chrome startup retry logic in Browser.Runtime with configurable `chrome_startup_retries` (default 1 retry).
- Added ChromeDriver startup log capture (`--verbose` + `--log-path`) and automatic error enrichment with log path and tail when startup remains unrecoverable.
- Added Runtime helper tests for retryable-error classification, retry-count config, and startup log tail formatting.
- Validation: `mix test test/cerberus/driver/browser/runtime_test.exs` passed; repeated Chrome runs for `test/cerberus/core/select_choose_behavior_test.exs` passed 5/5 after change.
