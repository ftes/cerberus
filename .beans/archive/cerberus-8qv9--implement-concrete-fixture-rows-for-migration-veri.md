---
# cerberus-8qv9
title: Implement concrete fixture rows for migration verification matrix
status: completed
type: task
priority: normal
created_at: 2026-02-28T15:08:23Z
updated_at: 2026-03-02T06:43:58Z
parent: cerberus-it5x
---

Missing-tests follow-up: migration verification matrix declares rows that are not yet implemented as fixture tests.

## Scope
- Add fixture scenarios for remaining matrix rows
- Wire rows into migration verification runner
- Keep matrix doc and implemented rows in sync

## Acceptance
- Matrix checklist item 'Every matrix row has a concrete fixture test case' can be checked

## Progress

- Added concrete fixture scenario files for pt_static_nav, pt_text_assert, pt_text_refute, pt_click_navigation, pt_path_assert, pt_path_refute, pt_scope_nested, and pt_live_click.
- Wired those row ids into the real-system migration verification integration test via explicit rows input.
- Verified end-to-end pre-migration test run + igniter rewrite + post-migration run passes for the expanded row set.

## Remaining

- Add fixture scenarios for the still-unimplemented matrix rows (form/check/upload/submit/multi-user-tab/live navigation/async timeout, plus Playwright rows).
- Decide whether/when expanded rows should become default runner rows vs integration-test-only rows.

## Progress Update

- Added matrix fixture rows pt_form_fill and pt_submit_action with deterministic pre/post assertions.
- Extended fixture app with search routes and form endpoints in router and page controller.
- Wired new rows into the real-system migration verification rows list.
- Updated migration verification matrix documentation to list these rows as implemented.
- Verified with mix test test/cerberus/migration_verification_test.exs and mix precommit.

## Notes

- pt_form_fill and pt_submit_action currently use explicit PhoenixTest function calls in the Phoenix branch to keep post-migration runs deterministic with current API differences between PhoenixTest submit/fill_in and Cerberus submit/fill_in.
- This triggers expected non-fatal direct-call migration warnings for those two files during migration runs.

## Progress Update 2

- Added matrix fixture row pt_checkbox_array with a dedicated checkbox fixture page and deterministic assertions for check/uncheck behavior.
- Extended fixture app routes and controller handlers for checkbox flow.
- Wired pt_checkbox_array into end-to-end migration verification rows and docs implemented list.
- Verified with mix test test/cerberus/migration_verification_test.exs and mix precommit.

## Notes 2

- pt_checkbox_array uses explicit PhoenixTest submit in Phoenix mode and Cerberus submit in Cerberus mode because static button click behavior differs across drivers for this flow.
- Migration run emits expected non-fatal direct-call warning for that explicit PhoenixTest submit branch.

## Progress Update 3

- Added matrix fixture row pt_multi_user_tab with a session-counter flow that validates same-user tab sharing and new-user isolation.
- Extended fixture routes/controllers for the session-counter endpoints.
- Wired pt_multi_user_tab into migration verification rows and the implemented-row list in the matrix doc.
- Validated row integration with migration verification test run in this branch context.

## Progress Update 4

- Tightened docs/migration-verification-matrix.md to align rows with source PhoenixTest/PhoenixTestPlaywright APIs (not Cerberus call shapes).
- Removed migration-row treatment of multi-user/tab APIs after validating PhoenixTest does not provide open_user/open_tab/switch_tab/close_tab.
- Added missing migration rows for unwrap/2 (PhoenixTest and Playwright) and clarified distinct LiveView row expectations to avoid overlap.
- Added a Source API Gaps (Manual Migration) section for select, choose, and open_browser so these omissions are explicit.

## Progress Update 5

- Removed pt_multi_user_tab from test/cerberus/migration_verification_test.exs row list so executable migration rows match source-API matrix scope.
- Multi-user/tab remains a Cerberus capability but is no longer treated as a PhoenixTest migration parity row.

## Progress Update 6

- Audited matrix rows for missing Cerberus implementation blockers.
- Identified upload static-route parity as a concrete Cerberus gap.
- Added matrix-table annotation on pt_upload and Source API Gaps entry referencing bean cerberus-xou2.
- Created bean cerberus-xou2 to implement static upload support in :phoenix sessions.

## Progress Update 7

- Added pt_unwrap fixture row and wired it into migration verification runner.
- Added pt_live_nav fixture row (patch + navigate flow) and wired it into runner.
- Added pt_live_change fixture row (phx-change form update) and wired it into runner.
- Removed blocked pt_upload row from runnable migration rows while keeping matrix row explicitly marked as blocked by cerberus-xou2.
- Updated fixture home route labels to keep link-text matches deterministic.
- Verified with mix test test/cerberus/migration_verification_test.exs (passes).

## Progress Update 8

- Added pt_live_async_timeout fixture row based on LiveView start_async/handle_async behavior and timeout-aware assertions.
- Wired pt_live_async_timeout into migration verification rows and matrix implemented list.
- Verified with mix test test/cerberus/migration_verification_test.exs (passes).\n

## Progress Update 9

- Reworked pt_select and pt_choose fixtures to submit via mode-aware helper (`PhoenixTest.submit/1` pre-migration, `Cerberus.submit/2` post-migration) instead of `click_button`, avoiding static-driver button-click limitations during post-migration runs.
- Validated end-to-end parity for these two rows via `Cerberus.MigrationVerification.run/1` (rows: pt_select, pt_choose), with both pre and post phases passing.

## Progress Update 10

- Added explicit Igniter migration verification coverage for upload by introducing a focused upload-row end-to-end test in test/cerberus/migration_verification_test.exs.
- Added a task-level migration test in test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs that verifies upload pipelines remain callable after import rewrite from PhoenixTest to Cerberus.
- Verified with mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs, mix test test/cerberus/migration_verification_test.exs, and mix precommit.

## Progress Update 11

- Fixed CI migration verification failure from run 22527296483 by committing missing fixture sources referenced by runnable rows.
- Added missing migration fixture feature files: pt_select, pt_choose, pt_unwrap, pt_live_change, pt_live_nav, and pt_live_async_timeout.
- Added missing fixture LiveView modules: LiveChangeLive, LiveNavLive, and LiveAsyncLive.
- Verified locally with mix test test/cerberus/migration_verification_test.exs and mix precommit.

## Progress Update 12

- Updated docs migration verification matrix checklist to reflect current reality: all non-browser PhoenixTest rows are covered and passing pre/post.
- Kept browser-only PhoenixTestPlaywright rows explicitly tracked as blocked by cerberus-55qd.
- Removed pt_multi_user_tab from matrix implemented rows and moved it to an explicit non-matrix scenario section.

## Summary of Changes

Completed the matrix-row fixture parity work for non-browser PhoenixTest APIs and aligned matrix documentation with actual execution scope. Remaining browser-only migration matrix work is now fully delegated to cerberus-55qd.
