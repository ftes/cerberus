---
# cerberus-glx2
title: Normalize return-result behavior for path/html/js helpers
status: completed
type: task
priority: normal
created_at: 2026-03-05T09:32:56Z
updated_at: 2026-03-05T09:41:32Z
---

Make current_path, render_html, and evaluate_js consistent around piping vs returning values.

## Todo
- [x] Audit current API behavior and call sites
- [x] Implement consistent callback or return_result option semantics
- [x] Update typespecs and docs/comments where needed
- [x] Add or update tests for pipe-preserving and pipe-breaking paths
- [x] Run format and targeted tests

## Summary of Changes
- Added shared return_result keyword option types/schema/validator in Cerberus.Options.
- Updated Cerberus.current_path to be pipe-preserving by default, with callback and return_result: true modes for extracting the value.
- Updated Cerberus.render_html/2 to support callback mode and return_result: true mode.
- Updated Cerberus.Browser.evaluate_js/3 to support callback mode and return_result: true, while keeping evaluate_js/2 as ignore-result pipeable behavior.
- Updated shim/legacy compatibility helpers to request current_path values explicitly via return_result: true.
- Added/updated tests for current_path, render_html, evaluate_js, live timeout usage, and compatibility snippets; all targeted tests pass.
