---
# cerberus-pk32
title: Support composed locators in assert_has/refute_has
status: completed
type: feature
priority: normal
created_at: 2026-03-04T19:21:08Z
updated_at: 2026-03-04T19:51:08Z
---

Implement assert_has/refute_has support for composed locators (:and/:or/:not) instead of raising InvalidLocatorError. Add parity tests in locator_parity_test and assertion-focused tests.

## Summary of Changes
Implemented first-class assertion support for composed locators in assert_has/refute_has across static/live/browser. Browser now resolves composed locators via in-browser JS assertion evaluation (no HTML snapshot fallback), including iframe-scoped contexts and closest/from handling.
