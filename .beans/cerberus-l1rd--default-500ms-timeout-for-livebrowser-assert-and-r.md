---
# cerberus-l1rd
title: Default 500ms timeout for live/browser assert and refute APIs
status: completed
type: task
priority: normal
created_at: 2026-02-28T20:22:04Z
updated_at: 2026-02-28T20:30:16Z
---

Implement default 500ms timeout for live and browser assert_*/refute_* functions, including path assertions, with event-driven waiting for navigation updates in both drivers.

## Summary of Changes

Implemented default 500ms assertion timeout semantics for live and browser sessions across all assert/refute APIs, including assert_path/refute_path.

- Added timeout option support to path assertions and wired retry behavior through timeout handling.
- Extended timeout retry orchestration to browser assertions so assert/refute retries now wait on browser readiness signals between attempts.
- Added browser-path refresh hooks used by path assertions while waiting.
- Set live/browser session default assertion timeout fallback to 500ms, while preserving per-call, per-session, and app-config overrides.
- Added live/browser async assertion coverage tests for default timeout behavior and path assertions.
- Updated README and docs guides to reflect new defaults and timeout support for path assertions.
- Ran mix format, targeted tests, and mix precommit successfully.
