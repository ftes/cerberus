---
# cerberus-8qv9
title: Implement concrete fixture rows for migration verification matrix
status: in-progress
type: task
priority: normal
created_at: 2026-02-28T15:08:23Z
updated_at: 2026-02-28T15:18:20Z
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
