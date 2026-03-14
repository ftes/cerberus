---
# cerberus-hxdd
title: Measure benchmark scenarios under Firefox
status: completed
type: task
priority: normal
created_at: 2026-03-13T09:58:16Z
updated_at: 2026-03-13T09:59:57Z
---

Run the Cerberus Playwright parity benchmark scenarios under Firefox and compare them with the Chrome results from the same committed tree.\n\n- [ ] run churn scenario under Chrome and Firefox\n- [ ] run locator-stress scenario under Chrome and Firefox\n- [x] summarize differences and limitations

## Summary of Changes\n\n- Measured the Cerberus benchmark runner on the committed churn and locator_stress scenarios under both Chrome and Firefox.\n- Observed that churn is effectively identical between Chrome and Firefox on this sample, while locator_stress is only modestly slower on Firefox.\n- The current pure JS Playwright harness remains Chromium-only, so these Firefox numbers are Cerberus-only for now.\n- Verified with:\n  - source .envrc && PORT=4481 MIX_ENV=test mix run bench/cerberus_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario churn\n  - source .envrc && CERBERUS_BROWSER_NAME=firefox PORT=4482 MIX_ENV=test mix run bench/cerberus_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario churn\n  - source .envrc && PORT=4483 MIX_ENV=test mix run bench/cerberus_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario locator_stress\n  - source .envrc && CERBERUS_BROWSER_NAME=firefox PORT=4484 MIX_ENV=test mix run bench/cerberus_playwright_liveview_flow_benchmark.exs --iterations 3 --warmup 1 --scenario locator_stress
