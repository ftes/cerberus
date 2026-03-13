---
# cerberus-7ctd
title: Broaden perf benchmark with modal and live search
status: completed
type: task
priority: normal
created_at: 2026-03-13T09:24:55Z
updated_at: 2026-03-13T09:31:00Z
---

Extend the Cerberus vs Playwright benchmark flow to use more realistic interaction patterns and more expensive locator composition: modal open, delayed live search suggestions, repeated options, nested cards, and more complex scoped lookups.

- [x] expand the shared performance fixture with modal and live-search behavior
- [x] update the Cerberus flow to use more realistic nested locators
- [x] update the Playwright flow to mirror the same user interactions
- [x] rerun the smoke test and both benchmark runners

## Summary of Changes

- Expanded the shared Playwright/Cerberus performance fixture to use a delayed candidate-search modal, live-search suggestions, repeated Choose buttons, a repeated-card results grid, a delayed review modal, `push_patch`, and `push_navigate`.
- Updated the Cerberus flow to use more realistic nested locators with multiple `filter(has: text(...))` constraints over repeated candidate options and result cards.
- Updated the Playwright flow to mirror the same end-user interactions and repeated-card narrowing with chained locator filters.
- Verified with:
  - `source .envrc && CERBERUS_PROFILE_COMPILE=1 PORT=4466 mix test test/cerberus/playwright_performance_benchmark_test.exs`
  - `source .envrc && MIX_ENV=test CERBERUS_PROFILE_COMPILE=1 PORT=4467 mix run bench/cerberus_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1`
  - `source .envrc && MIX_ENV=test CERBERUS_PROFILE_COMPILE=1 PORT=4468 mix run bench/run_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1`
