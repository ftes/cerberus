---
# cerberus-npb0
title: Unify locator pass-through and browser-side action resolution
status: completed
type: feature
priority: normal
created_at: 2026-03-03T08:36:41Z
updated_at: 2026-03-03T08:57:36Z
---

Implement locator pass-through from Assertions to drivers and migrate browser action operations to in-browser Playwright-style locator resolution/wait loops, then align static/live semantics and tests.

## Summary of Changes

- Implemented locator pass-through for action ops by removing assertion-layer reject/rewrite behavior and moving locator interpretation into driver-level `LocatorOps`.
- Added browser-side action resolver infrastructure (`ActionHelpers`, expression wiring, preload lifecycle) and migrated browser action ops to resolver-first matching.
- Preserved nested `:has` action behavior via a targeted snapshot+Elixir fallback path while all non-`has` action matching now resolves in-browser.
- Aligned static/live/browser action entrypoints and updated parity/API tests for the new semantics.
- Validation run: `mix format`, `mix test test/cerberus_test.exs test/cerberus/locator_parity_test.exs`, and `mix precommit` (with `.envrc` loaded).
