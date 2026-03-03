---
# cerberus-coeb
title: Remove legacy argument compatibility paths
status: completed
type: task
priority: normal
created_at: 2026-03-03T16:15:42Z
updated_at: 2026-03-03T16:23:51Z
---

Remove compatibility handling for legacy argument shapes (e.g. within CSS-selector strings and similar legacy call forms) since Cerberus is unreleased; update tests accordingly.

## Summary of Changes
- Removed dedicated legacy `within/3` binary-scope compatibility branch from `Cerberus.within/3`; raw string scopes now fail via normal function-clause matching.
- Removed legacy remote WebDriver URL fallback handling from browser runtime: dropped `chromedriver_url` and `webdriver_urls` resolution paths in `Runtime.remote_webdriver_url/1`.
- Removed corresponding legacy option keys from `Cerberus.Options` types, schemas, and validators (`chromedriver_url`, `webdriver_urls`).
- Updated runtime tests to remove legacy option coverage and keep only supported WebDriver URL paths.
- Updated README runtime-option docs to remove mention of legacy `webdriver_urls` compatibility.
- Updated tests that asserted the old `within/3` migration-specific ArgumentError message to assert strict function-clause rejection instead.
- Renamed `submit/1` test wording to non-compat framing and removed compatibility wording from `submit/1` docs.

## Validation
- `mix format`
- `source .envrc && mix test test/cerberus/driver/browser/runtime_test.exs test/cerberus/form_actions_test.exs test/cerberus_test.exs:405 --max-failures 1`
- `source .envrc && mix test test/cerberus_test.exs test/cerberus/driver/browser/runtime_test.exs --max-failures 1`
- `mix test test/cerberus/options_test.exs --max-failures 1`
