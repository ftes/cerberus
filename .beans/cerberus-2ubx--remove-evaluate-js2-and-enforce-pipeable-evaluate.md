---
# cerberus-2ubx
title: Remove evaluate_js/2 and enforce pipeable evaluate_js/3
status: completed
type: task
priority: normal
created_at: 2026-03-04T09:50:10Z
updated_at: 2026-03-04T09:52:51Z
---

Cleanly remove Browser.evaluate_js/2 (value-returning variant) from unreleased API and keep only callback-based, pipeable evaluate_js/3.\n\n- [x] Remove evaluate_js/2 from public API\n- [x] Update docs/examples to callback-only evaluate_js\n- [x] Update tests to stop using /2\n- [x] Run targeted tests and formatting\n- [x] Add summary and mark completed

## Summary of Changes
- Removed Browser.evaluate_js/2 from the public API, leaving only callback-based Browser.evaluate_js/3 to keep browser helpers pipeable.
- Updated all in-repo call sites to callback-only evaluate_js usage (tests, docs, and benchmark script).
- Updated docs examples to remove value-returning evaluate_js pattern and show callback assertion pattern only.
- Validation: mix format on changed Elixir files and PORT=4012 mix test test/cerberus/browser_extensions_test.exs test/cerberus/explicit_browser_test.exs test/cerberus/documentation_examples_test.exs (42 tests, 0 failures).
