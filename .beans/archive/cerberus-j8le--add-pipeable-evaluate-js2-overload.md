---
# cerberus-j8le
title: Add pipeable evaluate_js/2 overload
status: completed
type: task
priority: normal
created_at: 2026-03-04T12:45:26Z
updated_at: 2026-03-04T12:48:11Z
---

User requested re-adding Browser.evaluate_js/2 as a pipeable variant that ignores JS result while keeping evaluate_js/3 callback variant.


- [x] Add Browser.evaluate_js/2 that ignores result and stays pipeable
- [x] Add/adjust tests for evaluate_js/2 behavior
- [x] Update docs for evaluate_js/2 overload
- [x] Run focused tests with random PORT
- [x] Add summary and mark completed

## Summary of Changes

- Added Browser.evaluate_js/2 overload that evaluates JavaScript, ignores the returned value, and returns the original session for pipeable flows.
- Kept Browser.evaluate_js/3 callback variant unchanged for value assertions.
- Added browser extension coverage for the new no-callback form and for unsupported non-browser sessions using evaluate_js/2.
- Updated user docs to show both evaluate_js forms in the getting-started and cheatsheet guidance.
- Ran mix format and focused browser validation with source .envrc and a random PORT in the 4xxx range; browser_extensions_test passed with 31 tests and 0 failures.
