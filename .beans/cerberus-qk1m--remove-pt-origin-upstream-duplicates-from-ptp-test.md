---
# cerberus-qk1m
title: Remove PT-origin upstream duplicates from PTP test tree
status: completed
type: task
priority: normal
created_at: 2026-03-06T06:43:16Z
updated_at: 2026-03-06T06:44:17Z
---

## Goal
Remove duplicated PT-origin upstream test files from the PTP import tree now that PhoenixTest suites are already imported under test/cerberus/phoenix_test.

## Plan
- [x] Confirm exact duplicate files under test/cerberus/phoenix_test_playwright/upstream
- [x] Delete duplicated PT-origin files from PTP upstream tree
- [x] Run format and targeted test validation with random PORT and source .envrc
- [x] Add summary and close bean

## Summary of Changes
Removed PT-origin duplicate suites from the PTP import tree so PT coverage exists only under test/cerberus/phoenix_test.
Deleted files:
- test/cerberus/phoenix_test_playwright/upstream/assertions_test.exs
- test/cerberus/phoenix_test_playwright/upstream/live_test.exs
- test/cerberus/phoenix_test_playwright/upstream/static_test.exs

## Final Verification
- source .envrc and PORT=4721 mix format
- source .envrc and PORT=4721 mix test test/cerberus/phoenix_test_playwright
  - 31 tests, 0 failures, 4 skipped
