---
# cerberus-wjvq
title: Add Cerberus vs Playwright LiveView perf benchmark
status: completed
type: feature
priority: normal
created_at: 2026-03-13T09:03:29Z
updated_at: 2026-03-13T09:15:31Z
---

Add a shared DOM-heavy LiveView benchmark fixture plus matching Cerberus and pure-JS Playwright benchmark runners so we can compare browser-flow runtime on the same multi-step churn-heavy scenario.

- [x] add a dedicated churn-heavy LiveView fixture and routes
- [x] add a Cerberus benchmark runner for the shared flow
- [x] add a pure JS Playwright benchmark runner for the shared flow
- [x] verify the fixture and Cerberus benchmark locally
- [x] verify the Playwright benchmark locally with an existing Node 24 environment

## Summary of Changes

- Added a new churn-heavy shared LiveView benchmark fixture at /phoenix_test/playwright/live/performance plus a done page.
- Added a reusable Cerberus flow helper and a browser smoke test for the shared route.
- Added a Cerberus benchmark runner that measures repeated executions of the shared flow.
- Added a pure JS Playwright benchmark runner plus a small Elixir wrapper that boots the test endpoint and invokes the Node benchmark via mise.
- Added a minimal package.json and lockfile so Playwright can be installed locally in this repo, and pinned nodejs 24.13.0 in .tool-versions.
- Verified with:
  - source .envrc && CERBERUS_PROFILE_COMPILE=1 PORT=4461 mix test test/cerberus/playwright_performance_benchmark_test.exs
  - source .envrc && MIX_ENV=test CERBERUS_PROFILE_COMPILE=1 PORT=4462 mix run bench/cerberus_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1
  - source .envrc && MIX_ENV=test CERBERUS_PROFILE_COMPILE=1 PORT=4465 mix run bench/run_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1
