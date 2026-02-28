---
# cerberus-7ggs
title: Clarify exact:true support for text locator in assert_has
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:34:03Z
updated_at: 2026-02-28T07:35:17Z
---

Investigate whether exact:true should be accepted as a locator option when using text("...") with assert_has, verify current behavior in code/tests, and either confirm intended API or implement support.

## Summary of Changes

- Ran beans prime and validated API behavior in assertions, locator normalization, options validation, and core driver query matching code.
- Confirmed assert_has with text locator plus exact option is supported and widely used.
- Confirmed locator-level exact is also supported via keyword locator maps and locator sigil modifiers.
- No code changes were required.
