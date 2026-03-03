---
# cerberus-1k7w
title: 'Where are we losing most time in tests: Elixir or JavaScript?'
status: completed
type: task
priority: normal
created_at: 2026-03-03T12:51:28Z
updated_at: 2026-03-03T13:11:34Z
---

## Goal
Identify whether test runtime is primarily spent in Elixir or JavaScript execution paths.

## Scope
Phase 1: Instrument only Elixir, including explicit timing for any Elixir-side wait spent waiting on JS/browser responses.
Phase 2 (conditional): If JS appears to be a hotspot from Phase 1 results, add JavaScript-side instrumentation to break down time inside browser-executed code.

## Todo
- [x] Add Elixir-side timing instrumentation around key test-driver operations
- [x] Add dedicated timing buckets for Elixir wait time spent waiting for JS/browser completion
- [x] Run representative test subsets and collect aggregated timing data
- [x] Decide whether JS is a hotspot from collected data
- [x] If JS is a hotspot, add JS-side instrumentation and rerun measurement
- [x] Summarize findings with Elixir vs JS time split and next actions

## Summary of Changes
- Added a lightweight `CERBERUS_PROFILE` profiling collector (`Cerberus.Profiling`) with suite-level aggregation.
- Instrumented key driver operations (`visit`, `click`, `fill_in`, `submit`, `assert_has`, `refute_has`, path assertions) with per-driver timing buckets.
- Added dedicated Elixir wait buckets for browser roundtrips (`:evaluate_with_timeout`, `:await_ready`, `:navigate`) and decode overhead.
- Added JS-side timing markers for action and text assertion expressions, then aggregated those in Elixir as `:browser_js` buckets.
- Ran representative subsets across static/live/browser drivers:
  - `test/cerberus/cross_driver_text_test.exs`
  - `test/cerberus/form_actions_test.exs`
  - `test/cerberus/live_form_synchronization_behavior_test.exs`

### Findings (Elixir vs JS)
- Browser-side waiting dominates runtime by orders of magnitude:
  - `{:browser_wait, :evaluate_with_timeout}`: ~2439.9ms total
  - `{:browser_wait, :await_ready}`: ~1375.2ms total
  - `{:browser_wait, :navigate}`: ~961.7ms total
- Browser operation wall-time hotspots were `visit`, `click`, and `submit`.
- JS execution inside browser helpers was small:
  - `expressionActionPerformMs`: ~13.5ms total
  - `actionTotalMs`: ~13.1ms total
  - `expressionTextAssertionMs`: ~5.4ms total
- Conclusion: current hotspot is not JS compute; it is Elixir-side time blocked on browser/WebDriver roundtrips and readiness waits.

### Next Actions
- Focus optimization on reducing number/frequency of browser roundtrips and readiness waits (batching actions/assertions where safe, reducing redundant readiness checks, and minimizing full evaluate cycles in hot paths).
