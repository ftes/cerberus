---
# cerberus-bj39
title: Fix CI websocket browser test origin mismatch
status: completed
type: bug
priority: normal
created_at: 2026-03-02T06:00:16Z
updated_at: 2026-03-02T06:03:11Z
---

Investigate and fix websocket browser test failures in CI where origin host differs from configured endpoint host.

- [x] Inspect failing test path and websocket runtime setup
- [x] Identify root cause of BiDi timeout and origin rejection
- [x] Implement minimal fix avoiding conflicts with in-progress test edits
- [x] Run format and available checks
- [x] Update bean summary and status

## Summary of Changes

- Confirmed websocket CI lane sets CERBERUS_BASE_URL_HOST to docker bridge host and only overrides Cerberus base_url, leaving Endpoint url host at default localhost.
- Updated config/test.exs to set Endpoint url host from CERBERUS_BASE_URL_HOST with localhost fallback so Phoenix socket origin checks match the browser origin in websocket runs.
- Ran mix format, mix test test/cerberus/browser_extensions_test.exs, and mix precommit successfully.
- Attempted mix test.websocket for the failing module, but local docker on arm64 cannot pull selenium/standalone-chrome:145.0-20260222 (no matching manifest), so websocket lane could not be executed locally.
