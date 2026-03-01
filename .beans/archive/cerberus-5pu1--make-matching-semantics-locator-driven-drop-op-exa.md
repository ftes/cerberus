---
# cerberus-5pu1
title: Make matching semantics locator-driven (drop op exact/normalize_ws)
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:40:26Z
updated_at: 2026-02-28T07:49:12Z
---

Remove operation-level exact and normalize_ws options from assert/click/fill/check/upload/submit APIs and drivers. Keep exact matching as locator-level semantics (keyword locators and ~l modifiers). Update tests and docs accordingly.

## Summary of Changes

- Removed operation-level text matching options from public option schemas:
  - `click/3`, `assert_has/3`, `refute_has/3`, `fill_in/4`, `check/3`, `uncheck/3`, `upload/4`, and `submit/3` no longer accept `:exact` or `:normalize_ws`.
- Kept matching strictness locator-driven by preserving locator opts on normalized locators and applying them in driver matching.
- Added helper-constructor support for locator opts on `text/2`, `link/2`, `button/2`, `label/2`, and `role/2` (`:exact`, `:selector`), so call sites can use `text("...", exact: true)` style directly.
- Updated assertion normalization to reject `:selector` for assert/refute locators explicitly (instead of silently accepting a no-op).
- Updated static/live/browser driver match paths to merge locator opts with operation opts before text/label matching.
- Migrated tests/docs from operation-level `exact` usage to locator-level usage.
- Updated API example failure-message assertions to reflect the new option surface.

## Verification

- `mix format`
- `mix test test/cerberus/public_api_test.exs test/cerberus/locator_test.exs test/cerberus/driver/html_test.exs test/cerberus/driver/live_view_html_test.exs test/core/api_examples_test.exs test/core/auto_mode_test.exs test/core/live_form_synchronization_conformance_test.exs test/core/live_link_navigation_test.exs --exclude browser` (pass)
- `mix test --exclude browser` currently has one existing browser-readiness related failure in `test/core/screenshot_conformance_test.exs` despite exclusion.
