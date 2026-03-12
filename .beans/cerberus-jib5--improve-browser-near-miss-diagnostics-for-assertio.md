---
# cerberus-jib5
title: Improve browser near-miss diagnostics for assertions and actions
status: completed
type: bug
priority: normal
created_at: 2026-03-12T07:04:13Z
updated_at: 2026-03-12T07:11:15Z
---

Improve browser candidate reporting so composed locator assertions and action failures surface useful near-miss candidates with parity coverage across browser, static, and live.

- [x] inspect current browser assertion and action diagnostics payloads
- [x] implement near-miss candidate reporting for composed locator assertions
- [x] align browser action candidate previews with the new diagnostics
- [x] add parity-focused tests across applicable drivers
- [x] run format and targeted browser/non-browser tests
- [x] add summary of changes

## Summary of Changes

- Added composed-locator near-miss candidate scoring in the browser assertion helper so failed `assert_has`/`refute_has` errors can show scoped candidate values when there are no full matches.
- Reused the same composed-locator diagnostic scoring in browser action previews so click and submit failures stay aligned with assertion hints.
- Added non-browser fallback candidate values for composed css-scoped locator assertions to keep static, live, and browser error output in parity for the covered cases.
- Added regression tests covering composed css-plus-text assertion candidate hints on static and live routes, and reran focused browser/non-browser suites.
