---
# cerberus-tgnj
title: Core interaction/form actions parity slice
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:00:49Z
updated_at: 2026-02-27T11:38:42Z
parent: cerberus-zqpu
---

## Scope
Implement grouped interaction APIs inspired by PhoenixTest for static/live/browser parity where applicable.

## Capability Group
- click_link
- click_button
- fill_in
- select
- choose
- check / uncheck
- submit

## Notes
- Keep Cerberus session->session pipe semantics.
- Reuse existing locator normalization rules.
- Add integration coverage across static/live and browser where behavior is expected to align.

## Done When
- [x] Public API functions exist with docs and typespecs.
- [x] Cross-driver tests cover at least one happy path per action class (click, form input, form submit).
- [x] Error messages are explicit for unsupported driver/action combinations.

## Summary of Changes
- Added grouped public APIs in `Cerberus`: `click_link/3`, `click_button/3`, `fill_in/4` (positional value), and `submit/3`.
- Kept explicit unsupported messaging for `select/3`, `choose/3`, `check/3`, `uncheck/3` in this slice.
- Added shared option/value typing and NimbleOptions validation in `Cerberus.Options`, reused in `Cerberus`, `Cerberus.Assertions`, and `Cerberus.Driver` callback specs.
- Extended driver behavior + adapters with `fill_in`/`submit` operations and explicit unsupported/clear errors where appropriate.
- Added deterministic form fixtures/routes (`/search`, `/search/results`) and integration coverage in `test/core/form_actions_test.exs` for click/form/submit flows plus unsupported live-route error cases.
- Refactored browser/html driver internals to satisfy strict Credo complexity/nesting checks while preserving behavior.
- Verified with `mix credo --strict` (clean) and full `mix precommit` outside sandbox: 29 tests, 0 failures.
