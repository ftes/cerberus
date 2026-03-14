---
# cerberus-8t5e
title: Assess CI slowness and Playwright switch tradeoffs
status: completed
type: task
priority: normal
created_at: 2026-03-12T17:28:11Z
updated_at: 2026-03-12T17:32:10Z
---

Inspect the current Cerberus CI workflow and identify the biggest time contributors, then assess whether switching the browser driver to Playwright would likely reduce CI time or complexity. Verify Playwright custom selector engine and locator-composition support from official docs.

- [x] inspect current CI workflow and local timing shape
- [x] verify Playwright custom selector engine support from official docs
- [x] verify whether locator composition works with custom selector engines
- [x] summarize whether switching to Playwright is likely worth it

## Summary of Changes

- Inspected the current CI workflow and confirmed it does three heavyweight things sequentially: `mix precommit`, a full Chrome test pass, and a full Firefox test pass.
- Confirmed `mix precommit` itself includes format check, compile warnings, credo, dialyzer, and docs generation.
- Measured the local Chrome suite at 63.7s for 628 tests; the current workflow then repeats the full suite for Firefox as a separate step, so browser testing cost is intentionally doubled.
- Verified from official Playwright docs that custom selector engines are supported via `selectors.register()`, must be registered before page creation, and can be combined with built-in locators.
- Verified from official Playwright docs that locator composition works via chaining, `locator.filter({ has / hasNot / hasText })`, `locator.and()`, `locator.or()`, and `dialog.locator(otherLocator)`.
- Assessed the migration tradeoff: Playwright could replace some browser transport/actionability code, but custom selector engines alone would not cover Cerberus locator semantics like generic `not`, `closest(from:)`, and the full normalized locator AST. The main CI slowness today is the workflow shape, not the specific browser driver implementation.
