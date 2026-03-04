---
# cerberus-7a4l
title: Add render_html helper
status: completed
type: feature
priority: normal
created_at: 2026-03-04T06:29:52Z
updated_at: 2026-03-04T06:34:01Z
---

Add a render_html function that renders the current page HTML and yields it as LazyHTML to a required callback, with docs cross-linking open_browser and noting debugging/AI DOM inspection use.

## Todo
- [x] Locate existing HTML rendering/open_browser path and LazyHTML usage
- [x] Add render_html API with required callback receiving LazyHTML
- [x] Update docs with debugging/AI note and open_browser cross-links
- [x] Run format and targeted tests with PORT=4xxx
- [x] Add summary and complete bean

## Summary of Changes
- Added public render_html/2 API that requires an arity-1 callback and passes a LazyHTML snapshot.
- Added a render_html/2 driver callback and implementations for static, live, and browser drivers, reusing the same HTML snapshot path used by open_browser.
- Added API docs cross-linking render_html/2 and open_browser/1, with debugging and AI DOM-inspection guidance.
- Updated README with a debugging snapshot section for open_browser/1 and render_html/2.
- Added tests for static/live/browser render_html behavior and callback arity validation; ran formatting and targeted test files.
