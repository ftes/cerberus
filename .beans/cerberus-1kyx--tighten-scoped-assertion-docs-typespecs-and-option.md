---
# cerberus-1kyx
title: Tighten scoped assertion docs, typespecs, and option validation
status: completed
type: task
priority: normal
created_at: 2026-03-02T12:52:43Z
updated_at: 2026-03-02T13:02:41Z
---

Scope:
- [x] Replace scope_or_locator naming in docs/specs with explicit scope_locator and locator terms
- [x] Tighten broad term typespecs in public API where possible
- [x] Reuse shared public types across modules for driver-exposed functions
- [x] Validate remaining keyword option lists with NimbleOptions where missing
- [x] Run format, targeted tests, and precommit
- [x] Update bean summary and commit changes

## Summary of Changes

- Replaced ambiguous scoped-overload naming in Cerberus public API internals/docs with explicit scope_locator and locator terminology.
- Tightened public API typespecs by replacing broad term locator inputs with shared Locator.input type aliases and explicit option list types.
- Added a shared Locator.input type and reused it across Cerberus and Driver types to keep locator input contracts consistent.
- Added NimbleOptions-backed validation for browser keyword option APIs (type, press, with_dialog, with_popup, add_cookie) in Cerberus.Options and wired Browser APIs through those validators.
- Preserved add_cookie domain fallback behavior when validated options include domain: nil.
- Updated README and getting-started guide scoped assertion signature notes to match explicit scope_locator and locator argument naming.
- Added browser extension tests covering NimbleOptions validation failures for invalid keyword options.
- Validation run:
  - mix format
  - mix test test/cerberus/browser_extensions_test.exs
  - mix test test/cerberus/documentation_examples_test.exs test/cerberus_test.exs
  - mix precommit
