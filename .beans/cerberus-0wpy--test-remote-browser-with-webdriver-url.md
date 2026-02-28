---
# cerberus-0wpy
title: Test remote browser with webdriver_url
status: completed
type: task
priority: normal
created_at: 2026-02-28T17:49:36Z
updated_at: 2026-02-28T18:01:52Z
---

Add coverage for remote browser execution using webdriver_url.

## Scope
- Add/extend browser harness test(s) that exercise remote mode via webdriver_url.
- Consider using testcontainers to launch a browser container for the test.

## Acceptance Criteria
- [x] A test can connect to a remote browser endpoint using webdriver_url.
- [x] The test provisions or documents a reliable browser container strategy (prefer testcontainers).
- [x] CI/local notes clarify prerequisites and cleanup behavior.

## Summary of Changes
- Added testcontainers as a test dependency.
- Added `test/core/remote_webdriver_behavior_test.exs` to exercise browser flow via `webdriver_url` against `selenium/standalone-chromium` container wiring.
- Added runtime reset guardrails in the new test to avoid shared browser runtime leakage between test modules.
- Added README guidance for running the remote webdriver smoke test, including Docker prerequisite and cleanup behavior.
- Added opt-in + Docker-availability skip gating (`CERBERUS_REMOTE_WEBDRIVER=1`) so default test runs remain stable without Docker.
