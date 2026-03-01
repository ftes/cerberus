---
# cerberus-v4t5
title: Move browser assertions to browser-side wait loops
status: completed
type: feature
priority: normal
created_at: 2026-03-01T14:21:29Z
updated_at: 2026-03-01T14:33:19Z
---

Implement browser-driver assertion waiting inside browser JS (single RPC per assertion), removing Elixir retry loop for browser assert_has/refute_has/assert_path/refute_path.

## Todo
- [x] Audit current assertion semantics and options
- [x] Implement browser-side text assertion wait API (positive + negative)
- [x] Implement browser-side path assertion wait API (positive + negative)
- [x] Route browser assertions/path assertions through new APIs
- [x] Keep non-browser assertion behavior unchanged
- [x] Run mix format
- [x] Run targeted tests
- [x] Run mix precommit
- [x] Add summary of changes

## Summary of Changes
- Moved browser `assert_has` and `refute_has` waiting to a single browser-side async script evaluation per assertion (with in-browser mutation/poll waiting and match evaluation).
- Moved browser `assert_path` and `refute_path` waiting to browser-side async script evaluation, including full-navigation transition handling via unload signaling + remaining-time retry.
- Routed browser assertions to bypass `LiveViewTimeout` retry loops; non-browser drivers still use existing `LiveViewTimeout` behavior.
- Added timeout-aware browser script evaluation plumbing (`UserContextProcess` and `BrowsingContextProcess`) so one assertion call can wait in-browser for the full assertion timeout.
- Docs impact check: no public API surface changed, so no docs update required.
- Validation: `mix format`, focused assertion/browser tests, and `mix precommit` all pass.
