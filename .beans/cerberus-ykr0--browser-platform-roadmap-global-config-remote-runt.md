---
# cerberus-ykr0
title: 'Browser platform roadmap: global config, remote runtime, multi-browser matrix, and CI'
status: completed
type: feature
priority: normal
created_at: 2026-02-28T07:06:28Z
updated_at: 2026-02-28T08:44:19Z
---

Plan and implement the next browser-platform capabilities for Cerberus.

## Objective
Support configurable browser runtime behavior (global and per-test), broaden browser coverage, and make CI execution reliable and reproducible.

## Todo
- [x] Add global browser configuration for display size, user agent, and JavaScript to run on every new session and/or tab.
- [x] Prepare a concrete gap list of helpful PhoenixTestPlaywright and vanilla Playwright features currently missing in Cerberus.
- [x] Define and implement remote browser mode: connect to an already-running remote browser instead of starting local Chrome; clarify whether local chromedriver is needed in remote mode.
- [x] Add Firefox support and run harness conformance tests against all available supported browsers.
- [x] Evaluate which additional browsers should be supported via BiDi and document support policy.
- [x] Design CI setup for browser runs (browser installation, asset build requirements, orchestration); add mix tasks first if needed.
- [x] Support launching an individual test or module with browser-specific overrides (for example screen size), including isolation strategy for per-test browser instances.

## Notes
- Keep browser-tagged tests runnable outside Codex sandbox constraints.
- Preserve current shared-browser and shared-BiDi architecture where possible; explicitly document tradeoffs if per-test browser launch is introduced.

## Summary of Changes

- Implemented global browser defaults for runtime behavior and screenshots with per-call overrides.
- Added per-test/module browser override handling and documented isolation strategy.
- Implemented remote WebDriver mode (`webdriver_url`) that skips local browser/chromedriver launch.
- Added explicit browser targets (`session(:chrome)` and `session(:firefox)`) and harness browser matrix expansion.
- Provisioned Firefox + GeckoDriver path and verified cross-browser conformance matrix execution.
- Updated browser support policy with explicit additional-browser evaluation and source-backed recommendations.
- Added CI browser conformance matrix workflow for Chrome and Firefox with deterministic readiness checks.
