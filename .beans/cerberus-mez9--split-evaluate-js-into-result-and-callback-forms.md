---
# cerberus-mez9
title: Split evaluate_js into result and callback forms
status: completed
type: task
priority: normal
created_at: 2026-03-10T05:54:32Z
updated_at: 2026-03-10T05:58:49Z
---

## Goal

Replace Browser.evaluate_js return_result option with explicit result-returning and callback-based functions.

## Todo

- [x] Change Browser.evaluate_js to return the JS result
- [x] Add Browser.with_evaluate_js callback wrapper and remove return_result option path
- [x] Update docs and tests for the new API
- [x] Run format and targeted tests

## Summary of Changes

- Changed Browser.evaluate_js/2 to return the evaluated JS value directly.
- Added Browser.with_evaluate_js/3 as the pipe-preserving callback wrapper and removed the old evaluate_js/3 callback/return_result API surface.
- Updated browser facade docs, README, getting-started/cheatsheet docs, migration notes, and all affected tests/call sites.
- Ran mix format and source .envrc && PORT=4139 mix test test/cerberus/browser_extensions_test.exs test/cerberus/documentation_examples_test.exs test/cerberus/explicit_browser_test.exs test/cerberus/browser_timeout_assertions_test.exs test/cerberus/browser_iframe_limitations_test.exs test/cerberus/value_assertions_test.exs test/cerberus/locator_parity_test.exs test/cerberus_test.exs successfully.
