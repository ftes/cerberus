---
# cerberus-nwt7
title: Replace Floki with LazyHtml
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:01:09Z
updated_at: 2026-02-27T11:03:13Z
---

Migrate HTML parsing from Floki to LazyHtml across the codebase.\n\n## Todo\n- [x] Audit Floki usage and dependency references\n- [x] Replace parser usage with LazyHtml equivalents\n- [x] Update tests and docs as needed\n- [x] Run validation (at least targeted tests)

## Summary of Changes
- Replaced `Floki` usage in `lib/cerberus/driver/html.ex` with `LazyHTML` (`from_document`, `query`, `attribute`, `text`, `to_tree`).
- Added a local `parse_document/1` helper in the HTML driver to preserve tolerant parse behavior and return `:error` on parser exceptions.
- Removed `{:floki, ...}` from `mix.exs` and promoted `{:lazy_html, ">= 0.1.0"}` from test-only to a regular dependency.
- Updated `mix.lock` by unlocking `floki`.
- Validation: `mix test test/core/live_navigation_test.exs:21` passed, but full `mix test` remains intermittently flaky with browser-driver error `Cannot find context with specified id` in `Cerberus.CoreLiveNavigationTest`.
