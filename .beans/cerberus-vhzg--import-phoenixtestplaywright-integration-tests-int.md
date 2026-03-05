---
# cerberus-vhzg
title: Import PhoenixTestPlaywright integration tests into Cerberus
status: todo
type: feature
priority: normal
created_at: 2026-03-05T06:36:05Z
updated_at: 2026-03-05T06:36:08Z
blocked_by:
    - cerberus-zh82
---

## Goal
Add PhoenixTestPlaywright integration coverage into Cerberus with copied server fixtures and route namespaces, while converting test calls to Cerberus syntax.

## Scope
In scope integration files from ../ptp/test/phoenix_test:
- upstream/assertions_test.exs
- upstream/static_test.exs
- upstream/live_test.exs
- playwright_test.exs
- step_test.exs
- playwright/case_test.exs
- playwright/no_browser_pool_test.exs
- playwright/ecto_sandbox_test.exs
- playwright/ecto_sandbox_async_false_test.exs
- playwright/browser_launch_opts_test.exs

Out of scope from this bean:
- playwright/js_logger_test.exs
- playwright/browser_launch_timeout_test.exs
- playwright/cookie_args_test.exs
- playwright/firefox_test.exs
- playwright/multiple_browsers_parameterize_test.exs

## Phased Plan
- [ ] Phase 1: copy server-side fixtures from ../ptp/test/support (playwright, web_app, endpoint, router, helpers) into test/support/fixtures with minimal behavior drift
- [ ] Phase 2: add phoenix_test prefix to copied routes, including pw routes and upstream page or live routes, under /phoenix_test/*
- [ ] Phase 3: port upstream compatibility tests (upstream/assertions, upstream/static, upstream/live) with minimal structural changes
- [ ] Phase 4: port playwright feature integration tests in batches: case_test and no_browser_pool_test, then ecto sandbox tests, then playwright_test and step_test
- [ ] Phase 5: adapt or skip assertions that depend on unsupported lanes (firefox or websocket specific behavior)
- [ ] Phase 6: run mix format and targeted test batches using source .envrc and random PORT=4xxx after each batch
- [ ] Phase 7: run mix do format + precommit + test + test.slow before final commit for this bean

## Notes
- Follow current project policy of Chrome-only local and CI validation.
- Keep copied server modules close to upstream to reduce future sync cost.
