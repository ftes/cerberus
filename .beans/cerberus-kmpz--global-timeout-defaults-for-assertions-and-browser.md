---
# cerberus-kmpz
title: Global timeout defaults for assertions and browser readiness
status: in-progress
type: task
created_at: 2026-02-28T07:09:42Z
updated_at: 2026-02-28T07:09:42Z
---

Add global/default timeout configuration so callers do not need to pass timeout options on every operation.

## Scope
- Define app-level defaults for assertion retry timeout (`assert_has`/`refute_has`) and browser readiness timeout.
- Keep per-call/per-session overrides supported and documented.
- Wire defaults through options/session initialization and update docs/tests.

## Todo
- [ ] Introduce global config keys for default assertion timeout and browser-ready timeout.
- [ ] Apply defaults in assertion and browser session/runtime paths.
- [ ] Preserve explicit override precedence (call opts > session opts > app config > hardcoded fallback).
- [ ] Add tests for defaulting and override behavior.
- [ ] Document new config in README/docs.

## Log
- [x] Requested from user after identifying no current global timeout knob.
