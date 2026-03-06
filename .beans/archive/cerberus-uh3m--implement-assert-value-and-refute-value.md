---
# cerberus-uh3m
title: Implement assert_value and refute_value
status: completed
type: feature
priority: normal
created_at: 2026-03-06T11:32:52Z
updated_at: 2026-03-06T11:48:10Z
---

Add explicit value assertions that check the current JS value semantics consistently across drivers.

## Tasks
- [x] Inspect existing assert/refute assertion plumbing and identify integration points
- [x] Implement assert_value/refute_value in public Cerberus API and assertion dispatch
- [x] Add/adjust static/live/browser driver behavior for value assertions
- [x] Add focused tests for success and failure behavior
- [x] Run format and targeted test suite with random PORT
- [x] Update bean with summary and complete

## Summary of Changes
- Added explicit  and  APIs in  with dedicated option schema/docs.
- Added assertion dispatch plumbing in  and driver callbacks in .
- Implemented value assertions for static/live drivers by resolving form fields and reading current values from merged form defaults + tracked .
- Implemented browser value assertions with timeout-aware polling and current field-value reads from browser action resolver payloads.
- Extended browser action helper payloads to include current field value for form/file candidates.
- Added focused cross-driver tests in  (success, missing-field failures, browser timeout retry behavior).
- Updated README quickstart example to include .

## Verification
- Running ExUnit with seed: 733622, max_cases: 28
Excluding tags: [slow: true]

.....
Finished in 3.7 seconds (3.7s async, 0.00s sync)
5 tests, 0 failures
- Running ExUnit with seed: 85402, max_cases: 28
Excluding tags: [slow: true]

.........................
Finished in 2.0 seconds (2.0s async, 0.00s sync)
25 tests, 0 failures

## Summary of Changes Corrected
- Added explicit assert_value and refute_value APIs in Cerberus with a dedicated option schema.
- Added assertion dispatch plumbing in Cerberus.Assertions and new driver callbacks in Cerberus.Driver.
- Implemented value assertions for static and live drivers using merged form defaults plus tracked form_data.
- Implemented browser value assertions with timeout-aware polling and current field-value reads from browser resolver payloads.
- Extended browser action-helper candidate payloads to expose current field values for form and file candidates.
- Added focused cross-driver tests in test/cerberus/value_assertions_test.exs for success and failure behavior.
- Updated README quickstart example to include assert_value usage.

## Verification Commands
- source .envrc && PORT=4871 MIX_ENV=test mix test test/cerberus/value_assertions_test.exs
- source .envrc && PORT=4984 MIX_ENV=test mix test test/cerberus/options_test.exs test/cerberus/assertion_filter_semantics_test.exs test/cerberus/compat/phoenix_test_legacy_behavior_test.exs
