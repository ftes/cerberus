---
# cerberus-vzb7
title: Explain link and button locators vs role-based locators
status: completed
type: task
priority: normal
created_at: 2026-03-06T08:12:50Z
updated_at: 2026-03-06T08:14:49Z
---

## Goal
Explain why Cerberus has link and button locator kinds and how that relates to role-based locator patterns, including what Playwright does.

## Todo
- [x] Review docs and code references for locator kinds
- [x] Draft clear explanation for user
- [x] Add summary and complete bean

## Summary of Changes
Reviewed locator docs and implementation to confirm how link/button and role locators relate. Verified role locators normalize to core kinds (button/link/label/etc.), and that click behavior infers link/button kind from role when applicable. Confirmed project browser lane is WebDriver plus BiDi based and does not depend on Playwright as a library, while docs use Playwright as a comparison point.
