---
# cerberus-p7nq
title: Align browser helper polling backoff with Playwright
status: completed
type: task
priority: normal
created_at: 2026-03-13T10:56:10Z
updated_at: 2026-03-13T10:59:38Z
---

Update Cerberus browser-side assertion and action helper polling to use a Playwright-like backoff schedule instead of a fixed 50ms cadence, then rerun the parity benchmarks to measure impact.\n\n- [ ] inspect current helper polling implementation and local Playwright references\n- [ ] update browser helper backoff schedule for assertions and actions\n- [ ] rerun targeted benchmark and smoke coverage\n- [x] summarize impact and open questions

## Summary of Changes\n\n- Replaced the fixed periodic browser-side fallback polling timer in assertion and action helpers with a Playwright-like backoff schedule of 20, 50, 100, 100, 500 ms, while keeping the existing MutationObserver and requestAnimationFrame dirty-check flow.\n- Verified benchmark smoke coverage still passes.\n- Reran the parity benchmark and found no improvement: churn stayed roughly flat, while locator_stress got slower on both Chrome and Firefox in this small sample.\n- Verified with:\n  - source .envrc && PORT=4496 mix test test/cerberus/playwright_performance_benchmark_test.exs\n  - source .envrc && PORT=4497 MIX_ENV=test mix run bench/cerberus_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario churn\n  - source .envrc && PORT=4498 MIX_ENV=test mix run bench/cerberus_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario locator_stress\n  - source .envrc && CERBERUS_BROWSER_NAME=firefox PORT=4499 MIX_ENV=test mix run bench/cerberus_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario locator_stress
