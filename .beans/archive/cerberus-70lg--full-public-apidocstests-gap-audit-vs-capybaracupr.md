---
# cerberus-70lg
title: Full public API/docs/tests gap audit vs Capybara/Cuprite/Playwright
status: completed
type: task
priority: normal
created_at: 2026-02-28T14:56:05Z
updated_at: 2026-02-28T15:02:54Z
---

Perform a full pass over Cerberus public surface and tests.

## Checklist
- [x] Refresh memory from upstream docs: Capybara, Cuprite, Playwright, PhoenixTest/PhoenixTest.Playwright
- [x] Inventory Cerberus public API and documentation exposure
- [x] Identify accidentally exposed internals in code/docs
- [x] Review tests for missing coverage against documented/public behavior
- [x] Compare feature coverage vs Capybara/Cuprite/Playwright and list actionable gaps
- [x] Report findings and recommendations to user

## Summary of Changes

- Refreshed parity context from upstream docs for Capybara, Cuprite, Playwright, PhoenixTest, and PhoenixTest.Playwright.
- Audited Cerberus public/documented surface by inspecting ExDoc-exposed modules, API entrypoints, and guide extras.
- Identified likely accidental public exposure of internal driver and helper modules plus hidden-but-public helper functions used by test harness internals.
- Reviewed test coverage of documented/public behavior and noted concrete gaps (including untested public placeholders and pending migration matrix rows).
- Compiled feature-gap inventory versus Playwright/Cuprite/Capybara/PhoenixTest with actionable priorities.
