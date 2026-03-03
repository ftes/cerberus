---
# cerberus-dxfa
title: Detail operation-specific locator semantics for Playwright migration
status: completed
type: task
priority: normal
created_at: 2026-03-03T08:19:33Z
updated_at: 2026-03-03T08:21:10Z
---

Provide concrete, code-referenced examples of Cerberus operation-specific semantics and explain which are hard to encode as generic selector query/queryAll behavior.

## Summary of Changes
Mapped operation-specific locator and matching semantics in Cerberus Assertions/Options/Browser driver/Expressions. Identified exact places where behavior diverges per operation (locator kind normalization, candidate pool, match_by defaults, type guards, select option logic, assertion count/visibility/timeout behavior), and clarified what can/cannot be reduced to selector query/queryAll alone.
