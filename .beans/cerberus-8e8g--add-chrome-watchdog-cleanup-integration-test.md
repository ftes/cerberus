---
# cerberus-8e8g
title: Add Chrome watchdog cleanup integration test
status: in-progress
type: task
priority: normal
created_at: 2026-03-14T19:04:36Z
updated_at: 2026-03-14T21:49:08Z
---

Cover abrupt runtime VM exit for the Chrome runtime path, asserting both chromedriver and chrome are cleaned up by the shared watchdog, and rerun focused runtime integration coverage.

## Summary of Changes
- added a Chrome-lane runtime integration test that starts a real managed Chrome runtime in a child `mix run` process, waits for readiness, kills the child VM abruptly, and asserts both chromedriver and chrome are reaped by the shared watchdog
- changed runtime integration lane gating from a Firefox-only module skip to per-test skips so the same file now covers both Chrome and Firefox watchdog paths in their respective lanes
- verified the runtime integration file passes in both the default Chrome lane and the Firefox lane, and reran the default Chrome file multiple times without failure


## Follow-up
- default CI lane can hit the Chrome watchdog integration test without CHROME/CHROMEDRIVER configured, so change it to skip when real browser binaries are unavailable instead of hard failing.


- follow-up: changed the Chrome watchdog case to skip when `CHROME`/`CHROMEDRIVER` are not exported, instead of hard-failing; verified no-env runs skip all runtime-integration tests in the default lane, while sourced Chrome and Firefox lanes still execute their respective coverage.

## Notes
- default CI installs Chrome before running the main test lane, so the Chrome watchdog integration test should resolve installed binaries the same way runtime does rather than skipping on missing raw CHROME/CHROMEDRIVER env vars

## Summary of Changes
- removed the Chrome watchdog test's raw-env skip and taught it to resolve Chrome and chromedriver from CHROME/CHROMEDRIVER, configured browser paths, or the installed tmp current symlinks just like the runtime does
- verified test/cerberus/driver/browser/runtime_integration_test.exs passes in the sourced Chrome lane, the Firefox lane, and a Chrome run with browser env vars unset so it falls back to the installed binaries

## Notes
- full local Chrome lane exposed a real regression: the runtime integration helper starts a child mix run process without explicitly setting MIX_ENV=test, so under a full suite run it can boot in the wrong environment and fail with could not find application file: cerberus.app

## Notes
- after forcing child watchdog subprocesses to run in MIX_ENV=test, the full Chrome lane moved past the earlier startup crash and the focused runtime integration file passed in both Chrome and Firefox
- a subsequent full Chrome run still failed elsewhere, now in test/cerberus/timeout_defaults_test.exs with a browser-driver init Mint.TransportError closed during full-suite load; a focused rerun of that file passed
- the full Firefox lane passed locally with 639 tests, 0 failures, 1 skipped

## Notes
- current local process scan shows no obvious dangling Cerberus-managed browser processes: no chromedriver, no Google Chrome for Testing, no cerberus-browser-runtime-watchdog, and no fake_firefox or firefox process; only unrelated Brave and user Chrome crashpad handlers are present
