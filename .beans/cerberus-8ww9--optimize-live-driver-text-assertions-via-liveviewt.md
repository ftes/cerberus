---
# cerberus-8ww9
title: Optimize live-driver text assertions via LiveViewTest DOM
status: completed
type: task
priority: normal
created_at: 2026-03-01T15:37:41Z
updated_at: 2026-03-01T15:42:06Z
---

Replace live-driver assert_has/refute_has HTML render+reparse path with LiveViewTest DOM-backed checks and document the performance improvement prominently in README.

## Todo
- [x] Implement efficient live assert_has/refute_has path
- [x] Preserve assertion semantics (exact/regex/visible/scope)
- [x] Add or update tests for live assertion behavior
- [x] Update README with prominent performance note
- [x] Run mix format and targeted tests

## Summary of Changes
- Reworked live-driver assert_has and refute_has to read texts from LiveViewTest internal DOM state via proxy html tree, avoiding the render to HTML string and LazyHTML reparse path on each live assertion.
- Kept Cerberus matcher behavior in place by feeding extracted texts through existing Query matching, with safe fallback to previous HTML path if internal access fails.
- Added live visibility coverage with a new live test and fixture hidden text to verify visible true, visible false, and visible any assertion behavior.
- Added a prominent README performance section documenting the live assertion optimization and why it helps on large pages.
- Verified with mix format and targeted live tests run via direnv so .envrc variables are loaded.
