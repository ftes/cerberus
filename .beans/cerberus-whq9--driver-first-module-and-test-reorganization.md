---
# cerberus-whq9
title: Driver-first module and test reorganization
status: todo
type: feature
priority: normal
created_at: 2026-03-01T17:33:14Z
updated_at: 2026-03-01T17:33:33Z
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

## Phase Beans
- cerberus-8353: Align namespaces and file paths to driver-first structure
- cerberus-3z8l: Decompose large driver modules into focused per-driver components
- cerberus-qshc: Remove test harness and convert to explicit driver loops
- cerberus-6nzi: Reorganize tests to module-under-test naming in test/cerberus
- cerberus-cb0r: Update docs to match reorganized module structure and test strategy
