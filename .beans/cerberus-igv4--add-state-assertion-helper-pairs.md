---
# cerberus-igv4
title: Add state assertion helper pairs
status: completed
type: feature
priority: normal
created_at: 2026-03-06T13:08:31Z
updated_at: 2026-03-06T13:22:53Z
---

## Goal
Add first-class assert/refute helper pairs for element state predicates so callers can assert checked/disabled/selected/readonly without encoding state through value assertions.

## Todo
- [x] Add public API functions and typespecs for state assertion pairs
- [x] Wire assertion core/helpers and driver callback surface for state assertions
- [x] Implement static/live/browser driver behavior and error messages
- [x] Add tests for all new helper pairs across drivers
- [x] Update docs/examples for new assertion helpers
- [x] Run mix format
- [x] Run targeted tests with source .envrc and random PORT in 4xxx

## Summary of Changes
- Added new public assertion helper pairs: assert_checked/refute_checked, assert_disabled/refute_disabled, assert_selected/refute_selected, assert_readonly/refute_readonly.
- Refactored assertion plumbing so assert/refute helpers are thin wrappers over shared internal timeout/assertion core functions.
- Implemented clean-cut label semantics in locator-engine assertion paths so label locators resolve via associated form controls (not label text nodes).
- Updated browser assertion helper locator matching/state filtering to align with the new label semantics.
- Added state assertion tests across phoenix/browser drivers and updated assertion semantics coverage.
- Updated docs (cheatsheet + getting-started) and fixture pages with readonly control examples.

## Verification
- source .envrc && PORT=4317 mix test test/cerberus/state_assertions_test.exs test/cerberus/value_assertions_test.exs
- source .envrc && PORT=4316 mix test test/cerberus/state_assertions_test.exs test/cerberus/assertion_filter_semantics_test.exs test/cerberus/helper_locator_behavior_test.exs
- mix format
