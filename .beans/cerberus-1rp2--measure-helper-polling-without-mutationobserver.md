---
# cerberus-1rp2
title: Measure helper polling without MutationObserver
status: completed
type: task
priority: normal
created_at: 2026-03-13T11:10:59Z
updated_at: 2026-03-13T11:13:08Z
---

On top of the uncommitted browser helper backoff experiment, remove MutationObserver-driven dirty checking from assertion and action helpers, rerun the benchmark, and compare the impact.\n\n- [ ] remove MutationObserver-based dirty checking from helper polling\n- [ ] rerun smoke coverage and benchmark scenarios\n- [x] summarize whether observer removal helps or hurts

## Summary of Changes\n\n- Removed MutationObserver-based dirty invalidation from the uncommitted browser helper backoff experiment while keeping the Playwright-like timer schedule in place.\n- Verified smoke coverage still passes.\n- Benchmark impact: observer removal helped compared with the backoff-only variant on locator_stress, but it still did not beat the original fixed-50ms-plus-observer baseline.\n- Verified with:\n  - source .envrc && PORT=4500 mix test test/cerberus/playwright_performance_benchmark_test.exs\n  - source .envrc && PORT=4501 MIX_ENV=test mix run bench/cerberus_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario churn\n  - source .envrc && PORT=4502 MIX_ENV=test mix run bench/cerberus_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario locator_stress\n  - source .envrc && CERBERUS_BROWSER_NAME=firefox PORT=4503 MIX_ENV=test mix run bench/cerberus_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario locator_stress
