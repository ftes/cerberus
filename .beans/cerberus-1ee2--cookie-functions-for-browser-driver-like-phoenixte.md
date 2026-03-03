---
# cerberus-1ee2
title: Cookie functions for browser driver (like PhoenixTestPlaywright)
status: todo
type: feature
priority: deferred
created_at: 2026-03-03T20:30:42Z
updated_at: 2026-03-03T20:30:42Z
---

Add PhoenixTestPlaywright-style cookie APIs to Cerberus browser driver for parity and migration ergonomics.

Scope targets:
- add_cookies equivalent
- clear_cookies equivalent
- add_session_cookie equivalent

## Todo
- [ ] Design public Cerberus.Browser API shape for cookie parity helpers.
- [ ] Implement browser-driver support for bulk add, clear, and session-cookie convenience.
- [ ] Add browser integration tests for add/clear/session-cookie behavior.
- [ ] Document usage and migration mapping from PhoenixTest.Playwright.
