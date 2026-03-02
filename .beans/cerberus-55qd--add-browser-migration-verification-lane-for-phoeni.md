---
# cerberus-55qd
title: Add browser migration verification lane for PhoenixTest.Playwright rows
status: in-progress
type: task
priority: normal
created_at: 2026-02-28T18:02:12Z
updated_at: 2026-03-02T06:46:28Z
parent: cerberus-it5x
---

MigrationVerification currently runs only phoenix_test -> cerberus non-browser mode. Matrix Playwright rows (ptpw_*) cannot be executed end-to-end because browser lane and migration mapping for use PhoenixTest.Playwright.Case are not in place.\n\nScope:\n- Extend migration verification to support browser pre/post lane for selected rows.\n- Define migration handling for PhoenixTest.Playwright.Case/module usage so post-migration tests compile/run against Cerberus browser APIs.\n- Add deterministic CI strategy for browser migration rows.\n\nAcceptance:\n- At least one ptpw row (ptpw_screenshot) runs pre and post migration in CI or a dedicated browser job.\n- Matrix browser rows can be incrementally unblocked.

## Progress Update

- Added Cerberus.Playwright.Case case template so rewritten use PhoenixTest.Playwright.Case modules compile and run against browser sessions after migration.
- Added migration fixture row ptpw_screenshot using Playwright case pipeline and screenshot artifact assertion.
- Updated fixture test helper to set cerberus base URL for browser session startup.
- Expanded migration verification sample-suite glob from pt_ to pt* so ptpw rows are included in pre/post runs.
- Verified with mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs and mix precommit.

## Notes

- The ptpw screenshot row will skip unless Playwright node assets are installed in the fixture app.
- This lays the compile and execution foundation, but a dedicated browser lane is still needed to guarantee non-skipped ptpw execution in CI.
