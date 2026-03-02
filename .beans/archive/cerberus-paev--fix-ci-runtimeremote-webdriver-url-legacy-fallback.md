---
# cerberus-paev
title: Fix CI Runtime.remote_webdriver_url legacy fallback test
status: completed
type: bug
priority: normal
created_at: 2026-03-02T06:13:35Z
updated_at: 2026-03-02T06:14:47Z
---

Investigate CI failure in RuntimeTest where remote_webdriver_url/1 returns WEBDRIVER_URL from env instead of passed legacy chromedriver_url option.

- [x] Reproduce failing assertion with CI-like env
- [x] Decide intended precedence and implement minimal fix
- [x] Run format and targeted tests
- [x] Run precommit
- [x] Update bean summary and status

## Summary of Changes

- Reproduced the failure by running RuntimeTest with WEBDRIVER_URL set, which made global browser config inject a remote webdriver URL.
- Kept existing runtime precedence semantics (configured webdriver_url remains higher precedence than legacy chromedriver_url).
- Updated RuntimeTest legacy fallback case to explicitly clear browser config before asserting chromedriver_url fallback, so the test is stable under websocket CI env vars.
- Verified with mix format, full runtime_test module pass, targeted CI-like reproduction pass, and mix precommit pass.
