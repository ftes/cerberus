---
# cerberus-8qv9
title: Implement concrete fixture rows for migration verification matrix
status: in-progress
type: task
priority: normal
created_at: 2026-02-28T15:08:23Z
updated_at: 2026-02-28T17:20:06Z
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
