---
# cerberus-atqb
title: Investigate flaky browser assert_path on async redirect
status: completed
type: bug
priority: normal
created_at: 2026-03-01T20:46:05Z
updated_at: 2026-03-01T20:47:24Z
---

Investigate intermittent failure in Cerberus.BrowserTimeoutAssertionsTest where assert_path reports path/query mismatch despite matching path text. Determine browser-specific behavior and fix race in browser path assertion pipeline if needed.

## Summary of Changes

- Reproduced failure in  under Firefox () on first run.
- Ran 20 repeated runs in Chrome for the same test and did not reproduce.
- Classified as a possible Firefox-specific flake in browser  timing/helper state.
- Deferred fix for now per request; moving on to locator work.

## Corrected Summary

- Reproduced failure in test file test/cerberus/browser_timeout_assertions_test.exs at line 23 under Firefox using CERBERUS_BROWSER_NAME=firefox.
- Ran 20 repeated runs in Chrome for the same test and did not reproduce.
- Classified as a possible Firefox-specific flake in browser path assertion timing or helper state.
- Deferred fix for now per request.
