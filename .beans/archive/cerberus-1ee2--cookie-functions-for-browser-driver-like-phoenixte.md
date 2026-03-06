---
# cerberus-1ee2
title: Cookie functions for browser driver (like PhoenixTestPlaywright)
status: completed
type: feature
priority: deferred
created_at: 2026-03-03T20:30:42Z
updated_at: 2026-03-06T20:50:39Z
---

Add PhoenixTestPlaywright-style cookie APIs to Cerberus browser driver for parity and migration ergonomics.

Scope targets:
- add_cookies equivalent
- clear_cookies equivalent
- add_session_cookie equivalent

## Todo
- [x] Design public Cerberus.Browser API shape for cookie parity helpers.
- [x] Implement browser-driver support for bulk add, clear, and session-cookie convenience.
- [x] Add browser integration tests for add/clear/session-cookie behavior.
- [x] Document usage and migration mapping from PhoenixTest.Playwright.

## Summary of Changes
- Added `Browser.add_cookies/2`, `Browser.clear_cookies/1,2`, and Phoenix-aware `Browser.add_session_cookie/3` while keeping the cookie shape close to Playwright bulk cookie APIs.
- Extended browser driver cookie support with BiDi bulk add/clear operations, session-cookie encoding from `Plug.Session` options, regression coverage, and docs updates.
