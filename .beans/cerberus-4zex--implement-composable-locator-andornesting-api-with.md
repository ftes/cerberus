---
# cerberus-4zex
title: Implement composable locator and/or/nesting API with harness parity tests
status: completed
type: feature
priority: normal
created_at: 2026-03-03T09:28:35Z
updated_at: 2026-03-03T10:06:40Z
---

Implement first-class locator composition including AND, OR, and nested composition while keeping action strictness at execution.\n\nScope:\n- [x] Add canonical locator AST support for and/or composition and nesting\n- [x] Update public Cerberus locator helpers/docs/exdoc to canonical composable locators\n- [x] Route browser JS resolver through canonical composed locator semantics\n- [x] Add extensive harness tests comparing Elixir and JS behavior for composition\n- [x] Run format + targeted composition suites + precommit

## Summary of Changes

Implemented canonical composable locators across Cerberus with first-class and/or/nesting support and pipe composition helpers.

Delivered in this slice:
- Added canonical locator AST composition in Locator with recursive normalization and has/from composition helpers.
- Updated public Cerberus locator helpers and docs to return/use canonical locators, including and_/2, or_/2, has/2 and pipe overloads.
- Routed browser action resolution through canonical locator payloads and in-browser matching for and/or/has semantics.
- Updated static and live action matching to evaluate composed locators consistently.
- Added composition-focused harness coverage and parity cases for AND, OR strict uniqueness, and nested has semantics.
- Updated README, getting-started guide, cheatsheet, and moduledocs to reflect the new canonical locator API.

Validation:
- source .envrc && mix format
- source .envrc && mix precommit
- source .envrc && mix test test/cerberus/locator_test.exs test/cerberus/helper_locator_behavior_test.exs test/cerberus/locator_parity_test.exs test/cerberus/within_closest_behavior_test.exs
