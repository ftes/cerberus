---
# cerberus-ktpx
title: Refactor locator normalization API to normalize/normalize! split
status: completed
type: task
priority: normal
created_at: 2026-03-05T05:42:23Z
updated_at: 2026-03-05T05:46:50Z
---

## Goal
Flatten locator normalization flow so non-raising normalization is centralized, with a raising wrapper for call sites that want exceptions.

## Todo
- [x] Inspect current Locator normalize API and call sites
- [x] Implement normalize/normalize! split in Cerberus.Locator
- [x] Update call sites and tests to new contract
- [x] Run format and targeted tests
- [x] Summarize changes

## Summary of Changes
- Refactored Cerberus.Locator normalization flow into a non-raising normalize function that returns either ok or error, plus a raising normalize bang wrapper that preserves exception behavior.
- Updated internal locator helpers and composition paths to call normalize bang so existing behavior for public helpers is unchanged.
- Updated library call sites that require raising behavior to use normalize bang explicitly.
- Updated locator-related tests to use normalize bang where exceptions or normalized locators are expected, and added new tests for normalize success and error tuple return behavior.
- Ran format, targeted locator and form ownership tests, and full precommit checks successfully.
