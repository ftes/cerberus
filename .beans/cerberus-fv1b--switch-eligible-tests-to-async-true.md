---
# cerberus-fv1b
title: Switch eligible tests to async true
status: completed
type: task
priority: normal
created_at: 2026-03-01T13:23:12Z
updated_at: 2026-03-01T13:26:25Z
---

Goal: set ExUnit test modules to async: true where safe.

## Todo
- [x] Audit all current async: false modules
- [x] Switch eligible modules to async: true
- [x] Run mix format
- [x] Run mix precommit (blocked by pre-existing Credo finding in lib/cerberus/driver/browser/runtime.ex)
- [x] Add summary of changes

## Summary of Changes
- Switched `test/cerberus/core/browser_tag_showcase_test.exs` to `async: true`.
- Switched `test/cerberus/core/browser_timeout_assertions_test.exs` to `async: true`.
- Kept `test/cerberus/core/explicit_browser_test.exs` at `async: false` after runtime instability during validation.
- Confirmed remaining `async: false` modules are the global-state/serial suites.
- Docs impact check: no public API or docs changes required.
- `mix format` passes.
- `mix precommit` is blocked by existing Credo finding in `lib/cerberus/driver/browser/runtime.ex` (not touched in this bean).
- Browser test validation in this environment is flaky due BiDi runtime/session startup failures unrelated to these line changes.
