---
# cerberus-3a0j
title: Create deterministic fixture app pages for static/live/browser parity
status: completed
type: task
priority: normal
created_at: 2026-02-27T07:41:37Z
updated_at: 2026-02-27T08:23:40Z
parent: cerberus-syh3
---

## Scope
Build a fixture surface that all drivers can exercise consistently.

## Required Fixtures
- static page with stable text variants (visible/hidden/whitespace cases)
- live counter page with deterministic click update
- static and live redirect paths
- mismatch fixture to validate oracle diff output

## Done When
- [x] fixture endpoints are documented.
- [x] all conformance scenarios use only fixture routes.
- [x] no external network dependencies.

## Investigation Notes (2026-02-27)
- `cerberus` currently has no internal Phoenix test app wiring yet (`test/test_helper.exs` only starts ExUnit; no endpoint/router under `test/support`).
- `phoenix_test` itself uses an internal fixture app under `test/support/web_app/*` and starts it in `test/test_helper.exs` via `PhoenixTest.WebApp.Endpoint.start_link/0`.
- `phoenix_test_playwright` setup pattern: start `PhoenixTest.Playwright.Supervisor` in `test/test_helper.exs`, set `Application.put_env(:phoenix_test, :base_url, Endpoint.url())`, and run the app endpoint with `server: true` in `config/test.exs`.
- Example app (`/Users/ftes/src/ptpe`) follows exactly that pattern and can be copied into Cerberus fixture setup.

## Summary of Changes
- Added shared fixture definitions in `Cerberus.Fixtures` for routes, text markers, and action labels used across drivers and tests.
- Added an internal Phoenix fixture app under `test/support/fixtures` with endpoint, router, static pages, LiveView counter, LiveView redirect actions, and oracle mismatch pages.
- Updated `test/test_helper.exs` to start `Phoenix.PubSub` and the local fixture endpoint, then publish `:endpoint` and `:base_url` app env values.
- Extended the deterministic driver fixture model to include redirects and oracle mismatch routes while reusing `Cerberus.Fixtures` constants.
- Updated conformance tests to use only fixture route helpers and added dedicated conformance coverage for oracle mismatch fixtures.
- Documented fixture endpoints and semantics in `docs/fixtures.md` and linked from README.
