---
# cerberus-omzm
title: Harden browser runtime cleanup on test exit
status: completed
type: bug
priority: normal
created_at: 2026-03-01T13:57:04Z
updated_at: 2026-03-01T14:12:22Z
---

Implement robust test-exit cleanup for browser runtimes: owner-driven teardown, process-group TERM/KILL for local driver/browser trees, and validation that no orphaned driver/browser processes remain after tests.

## Todo
- [x] Audit current Runtime/UserContext teardown paths and identify missing owner/session cleanup
- [x] Implement owner-driven runtime session shutdown and reliable process-group kill for local services
- [x] Add or update regression tests for runtime owner exit and service stop semantics
- [x] Run format and targeted browser runtime tests
- [x] Run focused leak reproduction command to confirm cleanup improvements
- [x] Summarize changes and complete bean

## Summary of Changes
- Added deterministic suite-exit teardown in test/test_helper.exs via ExUnit.after_suite/1 by stopping Cerberus.TestSupportSupervisor, ensuring browser runtime shutdown completes before VM exit.
- Hardened UserContextProcess teardown to avoid re-spawning browser runtime sessions during shutdown: skip browser.removeUserContext when owner is already dead, and treat BiDi shutdown exits as best-effort.
- Isolated websocket disconnect failures from the BiDi socket manager by unlinking WS child processes in BiDiSocket, plus explicit socket closure in terminate/2.
- Preserved and kept previous runtime service-stop hardening in place (TERM/KILL with process-group/process-tree targeting).
- Validated with focused leak reproduction (mix test test/cerberus_test.exs:32), targeted suites, and mix precommit.
