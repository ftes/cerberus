---
# cerberus-rxqy
title: Browser-only extensions parity slice
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:00:49Z
updated_at: 2026-02-27T21:24:39Z
parent: cerberus-zqpu
---

## Scope
Add browser-only capability group inspired by PhoenixTest.Playwright for richer real-browser workflows.

## Capability Group
- screenshot
- keyboard helpers (type, press)
- drag interactions
- dialog handling helper (with_dialog pattern)
- cookie/session-cookie inspection helpers
- JavaScript evaluation helpers (evaluate_js parity)
- cookie mutation helpers (add_cookie parity)

## Notes
- Keep these APIs explicitly browser-driver scoped with clear unsupported errors elsewhere.
- Keep advanced APIs on the Browser module only; do not expose them on top-level Cerberus.
- Validate behavior with browser integration tests only.

## Done When
- [x] Browser driver implements the grouped capabilities with docs.
- [x] Non-browser drivers return explicit unsupported errors.
- [x] Integration tests demonstrate at least screenshot + keyboard + dialog handling flows.
- [x] Integration tests cover evaluate_js and add_cookie parity semantics.

## Summary of Changes
- Added a dedicated `Cerberus.Browser` module for browser-only helpers:
  `screenshot`, `type`, `press`, `drag`, `with_dialog`, `evaluate_js`,
  `cookies`, `cookie`, `session_cookie`, and `add_cookie`.
- Implemented browser extension internals in
  `Cerberus.Driver.Browser.Extensions` using BiDi/script primitives.
- Added fixture route `/browser/extensions` with deterministic keyboard, dialog,
  and drag interactions.
- Added integration coverage in `test/core/browser_extensions_test.exs` for:
  screenshot + keyboard + dialog + drag, evaluate_js decoding, add_cookie, and
  session-cookie inspection.
- Added explicit unsupported coverage for static/live sessions in the browser
  extension test module.
- Updated docs (`README.md`, `docs/fixtures.md`) with the new browser-only API
  and fixture route.
