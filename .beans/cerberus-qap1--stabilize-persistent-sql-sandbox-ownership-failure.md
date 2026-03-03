---
# cerberus-qap1
title: Stabilize persistent SQL sandbox ownership failures in full mix test
status: completed
type: bug
priority: normal
created_at: 2026-03-03T20:21:57Z
updated_at: 2026-03-03T20:44:28Z
---

Investigate recurring DBConnection.OwnershipError in Cerberus.SQLSandboxBehaviorTest during full suite runs and implement deterministic stabilization.

## Progress
- Identified cross-test interference source: test/cerberus/sql_sandbox_user_agent_test.exs was async and called sql_sandbox_user_agent with async: false, which forces shared sandbox mode.
- This could perturb concurrent async tests and intermittently invalidate ownership expectations.

## Summary of Changes
- Changed test/cerberus/sql_sandbox_user_agent_test.exs to use ExUnit.Case, async: false.
- Re-ran targeted SQL sandbox tests and stress loops with browser env loaded; no ownership errors reproduced.
- Ran full mix test once with browser env loaded; observed one unrelated profiling assertion mismatch, with no SQL sandbox ownership failure in that run.
