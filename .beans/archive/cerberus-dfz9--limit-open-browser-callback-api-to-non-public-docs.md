---
# cerberus-dfz9
title: Limit open_browser callback API to non-public docs
status: completed
type: task
priority: normal
created_at: 2026-03-04T09:34:43Z
updated_at: 2026-03-04T09:36:52Z
---

User requested to keep callback variant only for internal/test usage.

- [x] Audit open_browser/2 usage and determine if needed for tests
- [x] Hide open_browser/2 from public docs (@doc false)
- [x] Update README examples to document open_browser/1 + render_html/2 only
- [x] Run focused tests for open_browser/render_html behavior
- [x] Add summary and mark bean completed

## Summary of Changes
- Kept open_browser/2 for internal/testability use (tests rely on injected callback to avoid launching OS browser).
- Marked open_browser/2 as non-public with @doc false in lib/cerberus.ex; open_browser/1 remains the documented public entrypoint.
- Removed README callback example so public docs now show only open_browser/1 and render_html/2.
- Validation: PORT=4012 mix test test/cerberus/open_browser_behavior_test.exs test/cerberus_test.exs -> 53 tests, 0 failures.
