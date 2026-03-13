---
# cerberus-3sdw
title: Add locator-stress variant to Playwright parity benchmark
status: completed
type: task
priority: normal
created_at: 2026-03-13T09:41:55Z
updated_at: 2026-03-13T09:50:48Z
---

Extend the Cerberus vs Playwright benchmark with a second scenario focused on expensive locator composition and repeated narrowing, while keeping the current churn-heavy scenario intact for comparison.

- [x] expand the fixture with a locator-stress state and interactions
- [x] add the locator-stress flow to the Cerberus benchmark helper and smoke coverage
- [x] add the same locator-stress flow to the Playwright benchmark runner
- [x] rerun targeted tests and both benchmark commands

## Summary of Changes

- Added a second benchmark scenario, locator_stress, to the shared LiveView fixture with deeper repeated DOM, nested assignment panels, an assignment modal, and extra patch and navigate steps.
- Extended the Cerberus benchmark helper and smoke test so the same fixture now supports both the original churn-heavy flow and the new locator-stress flow.
- Extended the pure JS Playwright runner and both benchmark wrappers with a scenario switch so the two flows can be measured independently with the same output shape.
- Verified with:
  - source .envrc && PORT=4475 mix test test/cerberus/playwright_performance_benchmark_test.exs
  - source .envrc && MIX_ENV=test CERBERUS_PROFILE=1 CERBERUS_PROFILE_COMPILE=1 mix clean && PORT=4476 MIX_ENV=test CERBERUS_PROFILE=1 CERBERUS_PROFILE_COMPILE=1 mix run bench/cerberus_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario locator_stress
  - source .envrc && PORT=4477 MIX_ENV=test CERBERUS_PROFILE=1 CERBERUS_PROFILE_COMPILE=1 mix run bench/run_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario locator_stress
  - source .envrc && PORT=4478 MIX_ENV=test CERBERUS_PROFILE=1 CERBERUS_PROFILE_COMPILE=1 mix run bench/cerberus_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario churn
  - source .envrc && PORT=4479 MIX_ENV=test CERBERUS_PROFILE=1 CERBERUS_PROFILE_COMPILE=1 mix run bench/run_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario churn
