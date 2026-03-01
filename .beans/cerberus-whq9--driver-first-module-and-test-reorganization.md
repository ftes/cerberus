---
# cerberus-whq9
title: Driver-first module and test reorganization
status: todo
type: feature
created_at: 2026-03-01T17:33:14Z
updated_at: 2026-03-01T17:33:14Z
---

Execute driver-first codebase reorganization with focused module boundaries and module-aligned tests.

Scope:
- Primary organization axis: driver namespaces first.
- Concern splits (HTML vs Phoenix) only where they materially improve a given driver.
- Remove test harness and use explicit Elixir test loops for multi-driver scenarios.
- Keep integration contract tests under test/cerberus in CerberusTest.* modules.

Out of scope:
- CI lint check for test path/module mismatch.

## Todo
- [ ] Complete phase tasks for namespace alignment, driver decomposition, harness removal, test reorganization, and docs updates
