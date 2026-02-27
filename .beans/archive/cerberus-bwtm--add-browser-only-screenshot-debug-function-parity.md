---
# cerberus-bwtm
title: Add browser-only screenshot debug function parity
status: completed
type: task
priority: normal
created_at: 2026-02-27T19:55:35Z
updated_at: 2026-02-27T20:50:49Z
parent: cerberus-zqpu
blocking:
    - cerberus-rxqy
---

Add a dedicated screenshot function for browser-driven debug workflows and keep it explicitly browser-only.

## Scope
- Define screenshot API and options for browser sessions
- Implement screenshot in browser driver
- Return explicit unsupported errors in non-browser drivers
- Add browser integration coverage

## Done When
- [x] Browser screenshot API is documented with options and outputs
- [x] Browser driver captures screenshots reliably in tests
- [x] Static and live drivers return explicit unsupported errors
- [x] Browser integration tests cover representative screenshot flows

## Summary of Changes
- Added `screenshot/1` and `screenshot/2` to `Cerberus` as browser-only debug helpers.
- Added screenshot option validation (`:path`, `:full_page`) in `Cerberus.Options`.
- Implemented browser screenshot capture in `Cerberus.Driver.Browser` via `browsingContext.captureScreenshot`, with PNG file writing and temp-path fallback.
- Added explicit unsupported behavior assertions for static/live sessions.
- Added coverage in `test/cerberus/public_api_test.exs` and new cross-driver conformance test `test/core/screenshot_conformance_test.exs`.
- Documented screenshot API usage and semantics in `README.md`.
