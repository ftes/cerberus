---
# cerberus-it5x
title: End-to-end migration verification loop for PhoenixTest and PhoenixTestPlaywright
status: completed
type: feature
priority: normal
created_at: 2026-02-28T07:18:58Z
updated_at: 2026-02-28T14:02:34Z
---

Close the loop on Igniter rewrite correctness by proving that representative PhoenixTest and PhoenixTestPlaywright suites pass both before and after migration to Cerberus.

## Objective
Build an automated verification flow that demonstrates semantic equivalence of migrated tests.

## Scope
- Add a nested fixture project (generated from `mix phx.new`) that includes:
  - PhoenixTest non-browser tests that pass pre-migration.
  - PhoenixTestPlaywright browser tests that pass pre-migration.
- Add a migration verification step in our test flow:
  - Run fixture tests in original PhoenixTest/PhoenixTestPlaywright form and assert pass.
  - Run Igniter rewrite to Cerberus.
  - Run rewritten Cerberus tests and assert pass.
- Aim to cover all PhoenixTest and PhoenixTestPlaywright functions at least once across fixture tests.
- Include broad option coverage (not every variant combination, but representative options for each function).

## Todo
- [x] Define function/option coverage matrix for PhoenixTest and PhoenixTestPlaywright APIs.
- [x] Build nested fixture Phoenix project and baseline passing tests for both libraries.
- [x] Implement test harness/task that executes pre-migration pass, rewrite, and post-migration pass.
- [x] Add assertions/reports proving both before and after are green.
- [x] Integrate into CI/test flow with practical runtime constraints.
- [x] Document verification approach and coverage boundaries.

## Acceptance Criteria
- [ ] Pre-migration PhoenixTest/PhoenixTestPlaywright fixture suites pass.
- [ ] Post-migration Cerberus suite produced by Igniter passes.
- [ ] Coverage matrix shows all target functions exercised at least once.
- [ ] Automation can run repeatedly and deterministically in CI.

## Notes
- Focus on semantic confidence rather than exhaustive combinatorics.
- Browser-dependent checks should use existing browser runtime policies in this repo.
