---
# cerberus-22kx
title: Simplify internal test config setup
status: completed
type: task
priority: normal
created_at: 2026-03-03T15:13:47Z
updated_at: 2026-03-03T15:20:37Z
---

Goal: minimize internal test setup config in config/test.exs and test/test_helper.exs, inspired by PhoenixTest and PhoenixTestPlaywright.

## Tasks
- [x] Review current config/test.exs and test/test_helper.exs plus related runtime config consumption
- [x] Implement simplified minimal configuration for internal tests
- [x] Run mix format and targeted tests for config/bootstrap paths
- [x] Update bean with summary and complete

## Summary of Changes
- Simplified `config/test.exs` by removing browser runtime env wiring and keeping only baseline endpoint/repo/app config with compact env integer parsing.
- Reduced `test/test_helper.exs` to a tiny entrypoint that starts ExUnit and delegates setup/teardown to a support bootstrap module.
- Added `test/support/bootstrap.ex` to centralize database creation, supervisor startup, SQL sandbox initialization, endpoint boot/base_url setup, and runtime browser env wiring (`CHROME`, `CHROMEDRIVER`, remote webdriver envs).
- Ran `mix format` and targeted verification: browser config/runtime unit tests plus mixed-driver browser session tests.
