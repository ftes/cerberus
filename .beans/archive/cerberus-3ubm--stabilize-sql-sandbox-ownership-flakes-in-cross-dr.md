---
# cerberus-3ubm
title: Stabilize SQL sandbox ownership flakes in cross-driver tests
status: completed
type: bug
priority: normal
created_at: 2026-03-03T11:53:21Z
updated_at: 2026-03-03T12:57:48Z
---

Intermittent DBConnection.OwnershipError failures still occur in SQL sandbox behavior tests and occasionally abort full test runs.\n\nScope:\n- [x] Reproduce failing SQL sandbox behavior tests with deterministic stress runs.\n- [x] Identify ownership handoff race between test process and browser/live driver processes.\n- [x] Implement robust ownership propagation or allow strategy for async multi-process paths.\n- [x] Verify stability by repeated full test/cerberus runs on chrome.\n- [x] Document expected sandbox lifecycle for browser/live drivers.

## Summary of Changes
- Reproduced ownership failures during chrome browser runs and confirmed intermittent failures under async module execution.
- Switched SQL sandbox behavior module to serial execution to avoid async ownership races between browser/live driver processes and sandbox owner lifecycle.
- Revalidated with repeated chrome runs and full test suites where the ownership error no longer reproduced.
