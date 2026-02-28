---
# cerberus-55qd
title: Add browser migration verification lane for PhoenixTest.Playwright rows
status: todo
type: task
priority: normal
created_at: 2026-02-28T18:02:12Z
updated_at: 2026-02-28T18:02:26Z
parent: cerberus-it5x
---

MigrationVerification currently runs only phoenix_test -> cerberus non-browser mode. Matrix Playwright rows (ptpw_*) cannot be executed end-to-end because browser lane and migration mapping for use PhoenixTest.Playwright.Case are not in place.\n\nScope:\n- Extend migration verification to support browser pre/post lane for selected rows.\n- Define migration handling for PhoenixTest.Playwright.Case/module usage so post-migration tests compile/run against Cerberus browser APIs.\n- Add deterministic CI strategy for browser migration rows.\n\nAcceptance:\n- At least one ptpw row (ptpw_screenshot) runs pre and post migration in CI or a dedicated browser job.\n- Matrix browser rows can be incrementally unblocked.
