---
# cerberus-wnzu
title: Implement true multi-browser browser runtime in one test invocation
status: completed
type: task
priority: normal
created_at: 2026-02-28T20:05:04Z
updated_at: 2026-02-28T20:09:29Z
---

## Goal
Allow chrome and firefox browser lanes to execute in one mix test invocation (no single-runtime browser lock), while preserving lazy browser startup.

## Todo
- [x] Refactor browser runtime/BiDi transport to support per-browser lanes
- [x] Propagate browser lane identity through browser/user-context/browsing-context/extensions flows
- [x] Ensure harness :chrome/:firefox drivers map to real browser_name options
- [x] Add/adjust tests to prove mixed browser run behavior
- [x] Run format/tests and summarize

## Summary of Changes
- Reworked browser runtime internals to support lane-local runtime sessions keyed by browser (`:chrome` / `:firefox`) in one invocation.
- Added per-browser remote endpoint selection via `webdriver_urls` and test-env wiring for `WEBDRIVER_URL_CHROME` / `WEBDRIVER_URL_FIREFOX`.
- Updated BiDi transport/socket layers to maintain per-browser websocket sockets, subscribers, and pending-command cleanup on per-lane disconnect.
- Propagated browser lane identity through browser session struct, user context process, browsing context process, and browser extensions BiDi calls.
- Updated harness driver mapping so `:chrome` and `:firefox` explicitly set `browser_name` in session opts.
- Updated websocket mix task to provision all requested browsers and run a single `mix test` invocation with both remote lanes available.
- Added/updated tests for harness driver mapping, runtime `webdriver_urls`, and same-invocation cross-browser runtime execution.
- Updated docs to reflect `webdriver_urls` and single-invocation websocket multi-browser behavior.

## Validation
- mix format
- mix test test/cerberus/harness_test.exs test/cerberus/driver/browser/runtime_test.exs test/cerberus/timeout_defaults_test.exs
- mix precommit
- mix test.websocket --browsers chrome,firefox test/core/browser_cross_browser_runtime_test.exs
- mix test.websocket --browsers chrome,firefox --only remote_webdriver
- mix test.websocket --browsers chrome,firefox test/core/browser_tag_showcase_test.exs
