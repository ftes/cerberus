---
# cerberus-iq1g
title: Per-test/module browser overrides and isolation strategy
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:07:19Z
updated_at: 2026-02-28T08:26:47Z
parent: cerberus-ykr0
---

Support running specific tests/modules with browser-specific settings (for example viewport) and define whether that requires dedicated browser instances.

## Summary of Changes

- Added harness-level per-test/module session override resolution with explicit precedence:
  - run `session_opts` base,
  - context `session_opts` for all drivers,
  - context browser keyword opts (`browser: [...]`) for browser driver,
  - context `browser_session_opts` as final browser-only override.
- Added deep-merge behavior for nested `browser:` keyword options so viewport/user-agent/init script overrides compose predictably.
- Added focused harness tests covering merge precedence and validation errors.
- Documented per-test browser override usage and isolation strategy in README and docs (`architecture`, `getting-started`).
