---
# cerberus-gwq2
title: Measure Playwright benchmark on Firefox
status: completed
type: task
priority: normal
created_at: 2026-03-13T10:20:41Z
updated_at: 2026-03-13T10:24:34Z
---

Run the existing benchmark scenarios with Playwright on Firefox using the managed local Firefox binary, then combine those numbers with the Cerberus and Chromium Playwright results into one matrix.

- [x] run Playwright churn on Firefox
- [x] run Playwright locator_stress on Firefox
- [x] summarize one combined matrix

## Summary of Changes

- Added a small local fallback in the Playwright benchmark script so Firefox can launch with Playwright-managed Firefox when FIREFOX is unset.
- Installed Playwright Firefox under the repo's pinned Node and ran all Playwright scenario measurements sequentially.
- Verified with:
  - source .envrc && PLAYWRIGHT_BROWSER=chromium PORT=4487 MIX_ENV=test mix run bench/run_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario churn
  - source .envrc && PLAYWRIGHT_BROWSER=chromium PORT=4488 MIX_ENV=test mix run bench/run_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario locator_stress
  - source .envrc && unset FIREFOX && PLAYWRIGHT_BROWSER=firefox PORT=4489 MIX_ENV=test mix run bench/run_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario churn
  - source .envrc && unset FIREFOX && PLAYWRIGHT_BROWSER=firefox PORT=4490 MIX_ENV=test mix run bench/run_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario locator_stress
