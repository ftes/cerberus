---
# cerberus-q47v
title: Slim locator parity tests and enable CDP evaluate
status: completed
type: task
priority: normal
created_at: 2026-03-10T16:55:47Z
updated_at: 2026-03-10T16:58:28Z
---

## Goal

Simplify locator parity tests now that browser/static/live implementations are aligned, keeping only detached-snippet parity coverage that is not already exercised elsewhere, and enable CDP evaluate for the browser session used by those tests.

## Todo

- [x] Reduce locator_parity_test.exs to a minimal detached-snippet parity suite
- [x] Use CDP evaluate for the browser session in locator parity tests
- [x] Format and run targeted parity tests with a random PORT
- [x] Add a summary and complete the bean

## Summary of Changes

Replaced the large locator parity matrix with a small detached-snippet smoke suite in `test/cerberus/locator_parity_test.exs`. The new suite keeps only synthetic-DOM parity coverage that is not already exercised by route-backed cross-driver behavior tests.

Added `SharedBrowserSession.start!/1` so tests can opt into browser session options, and switched locator parity to `use_cdp_evaluate: true` for its browser session.

Verified with `source .envrc && PORT=4040 mise exec node@24 -- mix test test/cerberus/locator_parity_test.exs`, which passed in about 3 seconds with 4 tests and 0 failures.
