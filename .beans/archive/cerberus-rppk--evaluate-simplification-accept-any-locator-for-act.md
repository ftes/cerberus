---
# cerberus-rppk
title: 'Evaluate simplification: accept any locator for action APIs'
status: completed
type: task
priority: normal
created_at: 2026-03-03T08:24:38Z
updated_at: 2026-03-03T08:25:42Z
---

Assess whether click/fill_in/select/choose/check/upload/submit can stop rejecting/rewriting locator kinds and instead pass normalized locators through to drivers, with only shallow binary shorthand conversion where needed.

## Summary of Changes
Reviewed Assertions, Static/Live/Browser drivers, Html matcher layer, and contract tests. Conclusion: broad simplification is feasible, but current architecture hard-codes rewritten kinds in all drivers and has explicit tests expecting rejections. Safe simplification path is to keep only locator parsing + binary shorthand conversion, pass normalized locators to drivers, and move kind interpretation to driver/matcher logic (or keep legacy static/live path while simplifying browser-first Playwright path).
