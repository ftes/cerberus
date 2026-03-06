---
# cerberus-r793
title: Simplify locator generation/resolution and harness after refactor
status: completed
type: task
priority: normal
created_at: 2026-03-06T11:35:34Z
updated_at: 2026-03-06T12:00:05Z
---

## Goal
Audit and simplify locator generation and resolving paths after the clean-cut locator refactor.

## Todo
- [x] Re-audit locator/assertion generation paths for removable indirection
- [x] Simplify resolver code paths in browser and Elixir drivers where equivalent logic exists
- [x] Simplify test harness setup if remaining duplication is unnecessary
- [x] Run mix format
- [x] Run targeted tests with source .envrc and random PORT in 4xxx
- [x] Commit code and bean updates

## Summary of Changes
- Simplified locator option normalization in Cerberus.Locator by removing map/string-key compatibility paths and requiring keyword-list atom keys for opts.
- Simplified browser locator helper payload handling by removing legacy hasNot and composite value-member fallback branches in browser assertion helper logic.
- Simplified shared browser-session test harness usage by replacing duplicated local start/stop helpers with Cerberus.TestSupport.SharedBrowserSession in helper/path/within/select/live-trigger behavior tests.
- Ran mix format.
- Ran targeted suites with source .envrc and random PORT in 4xxx:
  - 157 tests, 0 failures, 1 skipped
  - 33 tests, 0 failures, 1 skipped
