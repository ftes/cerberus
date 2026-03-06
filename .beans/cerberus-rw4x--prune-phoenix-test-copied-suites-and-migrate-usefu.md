---
# cerberus-rw4x
title: Prune phoenix_test copied suites and migrate useful coverage to core
status: completed
type: task
priority: normal
created_at: 2026-03-06T08:51:55Z
updated_at: 2026-03-06T08:54:26Z
---

Remove overlapping tests copied from phoenix_test and phoenix_test_playwright, migrate remaining valuable checks into core Cerberus test modules, and delete phoenix_test/playwright test directories.

## Todo
- [x] Choose target core modules for migrated checks
- [x] Add migrated tests in core suites
- [x] Delete copied phoenix_test and phoenix_test_playwright test directories
- [x] Format and run targeted tests with source .envrc and random PORT=4xxx
- [x] Confirm removed directories are gone and report final diff

## Summary of Changes
Removed copied test suites under test/cerberus/phoenix_test and test/cerberus/phoenix_test_playwright (directories fully deleted). Migrated useful non-overlap coverage into core suites by adding prefixed fixture current_path/path assertions in test/cerberus/current_path_test.exs and delayed browser SQL sandbox LiveView assertions in test/cerberus/sql_sandbox_behavior_test.exs. Ran mix format and targeted validation with source .envrc and random PORT values (PORT=4567 and PORT=4568), and confirmed no files remain under test/cerberus/phoenix_test* via rg.
