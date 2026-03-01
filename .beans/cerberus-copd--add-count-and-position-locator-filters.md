---
# cerberus-copd
title: Add count and position locator filters
status: completed
type: feature
priority: normal
created_at: 2026-03-01T16:00:44Z
updated_at: 2026-03-01T20:29:42Z
blocked_by:
    - cerberus-1xnx
---

Support count/position matching constraints (count/min/max/between, first/last/nth/indexed selection) in locator APIs and driver implementations with parity tests.

## Prerequisite
- Complete cerberus-1xnx rich locator oracle corpus updates first; preserve and extend that corpus as this bean lands.


## Todo
- [x] Fix and finalize option validation for count/position filters
- [x] Wire count/position selection into static/live/html locator resolution
- [x] Wire count/position selection into browser locator resolution
- [x] Apply count constraints to assert_has/refute_has across static/live/browser
- [x] Expand Elixir-vs-JS locator oracle harness with extensive count/position parity cases
- [x] Run format + focused tests + precommit and commit

## Summary of Changes
- Added first-class count and position filters (`count`, `min`, `max`, `between`, `first`, `last`, `nth`, `index`) to locator option validation and query selection helpers.
- Wired count/position matching across HTML/static/live/browser locator resolution paths, including live clickable-button matching and browser-side field/clickable picking.
- Applied count-filter semantics to `assert_has`/`refute_has` for static/live/browser; browser assertion helpers now evaluate count-filter outcomes consistently.
- Expanded Elixir-vs-JS parity coverage in `locator_oracle_harness_test.exs` with extensive count/position cases plus added focused unit tests for `Cerberus.Query`, `Cerberus.Options`, `Cerberus.Html`, and `Cerberus.Phoenix.LiveViewHTML`.
- Ran `mix format`, focused warning-as-error test suites, and `mix precommit`; precommit remains blocked by existing dialyzer warnings in `lib/cerberus/driver/browser/extensions.ex` unrelated to this bean.
