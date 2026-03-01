---
# cerberus-kmpz
title: Global timeout defaults for assertions and browser readiness
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:09:42Z
updated_at: 2026-02-28T08:01:15Z
---

Add global/default timeout configuration so callers do not need to pass timeout options on every operation.

## Scope
- Define app-level defaults for assertion retry timeout (`assert_has`/`refute_has`) and browser readiness timeout.
- Keep per-call/per-session overrides supported and documented.
- Wire defaults through options/session initialization and update docs/tests.

## Todo
- [x] Introduce global config keys for default assertion timeout and browser-ready timeout.
- [x] Apply defaults in assertion and browser session/runtime paths.
- [x] Preserve explicit override precedence (call opts > session opts > app config > hardcoded fallback).
- [x] Add tests for defaulting and override behavior.
- [x] Document new config in README/docs.

## Log
- [x] Requested from user after identifying no current global timeout knob.

## Summary of Changes
Implemented global timeout defaults for assertion retries and browser readiness.
Added app config key assert_timeout_ms and session-level override assert_timeout_ms for static/live/browser sessions.
Assertion precedence is now call timeout option, then session assert_timeout_ms, then app config, then fallback.
Browser ready timeout now reads config :cerberus, :browser ready_timeout_ms when session opts do not provide ready_timeout_ms.
Added timeout default tests in test/cerberus/timeout_defaults_test.exs and updated README and docs guides for configuration usage.
