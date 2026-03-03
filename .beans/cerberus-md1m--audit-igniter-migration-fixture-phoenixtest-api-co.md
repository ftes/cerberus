---
# cerberus-md1m
title: Audit Igniter migration fixture PhoenixTest API coverage
status: completed
type: task
priority: normal
created_at: 2026-03-03T15:10:48Z
updated_at: 2026-03-03T15:27:49Z
---

## Goal
Verify whether the Igniter migration fixture project covers the full PhoenixTest API surface.

## Todo
- [x] Enumerate PhoenixTest public API used by migration tooling
- [x] Enumerate fixture project API usage coverage
- [x] Compare and report gaps

## Summary of Changes
Compared PhoenixTest public functions from fixtures/migration_project/deps/phoenix_test/lib/phoenix_test.ex against fixture usage in fixtures/migration_project/test/features.
Confirmed fixture coverage is not the entire API.
Identified uncovered PhoenixTest functions in the fixture: open_browser and submit.
Also confirmed docs already state intentional non-exhaustive scope and list open_browser as manual-migration gap.

## Follow-up
Implement fixture and matrix changes to cover submit/1 in migration verification, while keeping open_browser excluded.

## Follow-up Todo
- [x] Update fixture submit scenario to use submit/1
- [x] Update migration matrix/docs to reflect submit coverage
- [x] Run format and focused migration tests

## Summary of Changes (Follow-up)
- Updated fixtures/migration_project/test/features/pt_submit_action_test.exs to exercise submit/1 directly and assert submit-button payload propagation.
- Updated fixtures/migration_project/lib/migration_fixture_web/controllers/page_controller.ex to include a named submit button and render submitted source value for verification.
- Updated docs/migration-verification-matrix.md submit row wording to match implemented submit/1 coverage.
- Ran mix format and focused tests: fixture pt_submit_action test and root migration-task slow tests.

## Summary of Changes (Compatibility)
- Added Cerberus.submit/1 compatibility in lib/cerberus.ex for migrated PhoenixTest submit() pipelines (defaults to submit-capable button selector).
- Added cross-driver coverage in test/cerberus/form_actions_test.exs to verify submit/1 works in both :phoenix and :browser sessions.
- Kept migration slow-test scope unchanged (pre + rewrite) to avoid broad pre-existing post-migration incompatibility failures unrelated to this gap fill.
