---
# cerberus-rdbd
title: Restore full last_result payload with driver field
status: completed
type: task
priority: normal
created_at: 2026-03-03T19:38:55Z
updated_at: 2026-03-03T19:41:53Z
---

## Goal
Re-expand Cerberus.Session.LastResult to keep rich observed payloads for diagnostics/tests while replacing mode metadata with driver module names.

## Todo
- [x] Update LastResult struct and Session.transition implementation to use observed payload
- [x] Restore observed payload retention in driver/session update helpers
- [x] Add driver module metadata where mode was previously used
- [x] Update or add tests for restored fields
- [x] Run mix format and targeted tests

## Summary of Changes
- Restored rich last_result payloads by extending Cerberus.Session.LastResult with observed and transition fields.
- Added LastResult.new/3 to auto-populate observed.driver with the session struct module when missing.
- Updated Cerberus and all driver update helpers to build last_result with source context so driver metadata is consistently present.
- Restored browser settle diagnostics assertions to use last_result.observed.readiness and assert driver equals Cerberus.Driver.Browser.
- Validation: mix format; targeted suites passed (53 tests) and additional related suites passed (78 tests).
