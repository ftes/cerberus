---
# cerberus-3t3g
title: Support css and selector-based assertions
status: completed
type: feature
priority: normal
created_at: 2026-03-04T19:21:08Z
updated_at: 2026-03-04T19:51:08Z
---

Allow css locators and selector option for assert_has/refute_has by routing through node-level assertion filtering rather than rejecting these locator forms.

## Summary of Changes
Enabled css- and selector-based assertion locators in assert_has/refute_has by routing advanced locator forms through locator-engine assertion paths instead of rejecting them. Updated parity coverage and browser iframe assertion coverage for composed css+text assertions.
