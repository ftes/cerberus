---
# cerberus-8e8g
title: Add Chrome watchdog cleanup integration test
status: completed
type: task
priority: normal
created_at: 2026-03-14T19:04:36Z
updated_at: 2026-03-14T19:07:23Z
---

Cover abrupt runtime VM exit for the Chrome runtime path, asserting both chromedriver and chrome are cleaned up by the shared watchdog, and rerun focused runtime integration coverage.

## Summary of Changes
- added a Chrome-lane runtime integration test that starts a real managed Chrome runtime in a child `mix run` process, waits for readiness, kills the child VM abruptly, and asserts both chromedriver and chrome are reaped by the shared watchdog
- changed runtime integration lane gating from a Firefox-only module skip to per-test skips so the same file now covers both Chrome and Firefox watchdog paths in their respective lanes
- verified the runtime integration file passes in both the default Chrome lane and the Firefox lane, and reran the default Chrome file multiple times without failure
