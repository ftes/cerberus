---
# cerberus-ql0l
title: Support assert_download across live static and browser
status: completed
type: feature
priority: normal
created_at: 2026-03-02T19:56:54Z
updated_at: 2026-03-03T21:23:13Z
---

Goal: support assert_download consistently across live, static, and browser drivers.

Scope:
- [x] Define public assert_download API semantics and callback contract shared by all drivers
- [x] Implement assert_download for static and live drivers
- [x] Ensure browser assert_download behavior matches shared semantics
- [x] Add cross-driver tests in test/cerberus that verify parity
- [x] Update docs with examples and driver notes

## Summary of Changes

- Extended Browser.assert_download/3 to support browser, static, and live sessions with the same sequential flow: click then assert_download.
- Kept browser behavior event-driven (BiDi download events) and non-consuming.
- Added static/live behavior by checking response content-disposition filename headers on the current response, which supports controller download responses reached via redirects.
- Added test coverage for static and live download assertions, plus mismatch messaging for static/live responses.
- Updated fixture live page links and docs to clarify that assert_download/3 is available across drivers while most Browser helpers remain browser-only.
