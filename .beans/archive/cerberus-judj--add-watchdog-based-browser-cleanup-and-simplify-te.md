---
# cerberus-judj
title: Add watchdog-based browser cleanup and simplify test shutdown wiring
status: completed
type: task
priority: normal
created_at: 2026-03-03T07:25:21Z
updated_at: 2026-03-03T07:34:00Z
---

## Goal
Prevent dangling local browser/driver processes in interrupted test runs (including Ctrl+C) while preserving lazy launch, and simplify test helper cleanup wiring.

## Todo
- [x] Design watchdog lifecycle for managed browser services
- [x] Implement watchdog start/stop integration in browser runtime
- [x] Simplify test helper shutdown wiring for normal suite completion
- [x] Add/adjust runtime tests for watchdog behavior
- [x] Run format and targeted tests (including browser lane)
- [x] Summarize docs impact and results

## Summary of Changes
Implemented watchdog-based fallback cleanup for managed local browser services in Runtime. Each managed service now starts with a unique marker file and detached watchdog process that monitors Runtime process liveness; if Runtime dies unexpectedly (e.g. Ctrl+C without graceful teardown), watchdog terminates the service process group/tree and removes the marker. On normal cleanup, Runtime removes the marker before graceful stop to disable watchdog kill. Kept lazy launch semantics unchanged (watchdog only starts when managed service starts).

Simplified test helper shutdown by extracting deterministic supervisor stop into Cerberus.TestHelperSupport.stop_test_support_supervisor/0 and invoking it from ExUnit.after_suite.

## Validation
- mix format lib/cerberus/driver/browser/runtime.ex test/test_helper.exs
- mix test test/cerberus/driver/browser/runtime_test.exs test/cerberus/driver/browser/config_test.exs test/cerberus/driver/browser/ws_test.exs (27 tests, 0 failures)
- Escalated browser run with env loaded: set -a; source .envrc; set +a; PORT=4131 MIX_ENV=test mise exec -- mix test test/cerberus/browser_multi_session_behavior_test.exs (2 tests, 0 failures)

## Docs Impact Check
No public API/behavior docs update required: changes are internal runtime/test harness cleanup mechanics.
