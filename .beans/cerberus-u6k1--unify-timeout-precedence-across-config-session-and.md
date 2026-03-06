---
# cerberus-u6k1
title: Unify timeout precedence across config, session, and calls
status: completed
type: feature
priority: normal
created_at: 2026-03-06T22:01:47Z
updated_at: 2026-03-06T22:10:54Z
---

## Context

Cerberus currently uses assertion-specific defaults named assert_timeout_ms and inconsistent fallbacks across drivers. The requested precedence is:

global all-driver config < global per-driver config < session opt < function opt

The user also wants a single default timeout concept for assertions and actions. Browser, live, and static should each be able to have their own global default via config, but per-call timeout must remain highest priority.

## Scope

- Replace the session/config default from assert_timeout_ms with a unified timeout_ms.
- Support global all-driver config plus per-driver config precedence.
- Use the session default timeout for assertions, actions, and path assertions.
- Preserve explicit session overrides across driver transitions; otherwise re-resolve using the target driver default.
- Update targeted timeout tests and docs.

## Todo

- [x] Replace session/config timeout plumbing with unified timeout precedence
- [x] Update driver fallback behavior for assertions, actions, and path assertions
- [x] Add/update focused timeout tests for precedence and driver defaults
- [x] Update docs and examples to use timeout_ms and per-driver config

## Summary of Changes

- Replaced the session default timeout shape with unified timeout_ms precedence across all-driver config, per-driver config, session opts, and call opts.
- Applied the unified timeout default to assertions, actions, and path assertions across static, live, and browser drivers.
- Preserved explicit session timeout overrides across static and live driver transitions while re-resolving target-driver defaults for non-overridden sessions.
- Added focused timeout coverage for per-driver config precedence, driver-transition behavior, and action fallback behavior, and updated the timeout docs.
