# Migration Fixture Project

This nested Phoenix app is a deterministic migration fixture used by Cerberus tests.

It intentionally contains baseline pre-migration tests using:

- `PhoenixTest`
- `PhoenixTest.Playwright`

The migration verification runner copies this project to a temp directory, runs the
baseline tests, applies `mix igniter.cerberus.migrate_phoenix_test`, then runs the
rewritten tests.

Playwright fixture test setup:

- Install browser assets in fixture project: `npm --prefix assets install playwright`
- Run browser baseline test: `mix test test/features/phoenix_test_playwright_baseline_test.exs`
