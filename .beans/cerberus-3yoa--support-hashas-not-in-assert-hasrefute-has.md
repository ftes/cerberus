---
# cerberus-3yoa
title: Support has/has_not in assert_has/refute_has
status: completed
type: feature
priority: normal
created_at: 2026-03-04T19:21:08Z
updated_at: 2026-03-04T19:51:08Z
---

Enable nested has/has_not filters in assertion locators/options for assert_has/refute_has and add coverage for positive/negative nested filtering.

## Summary of Changes
Enabled has/has_not assertion locators for assert_has/refute_has in static/live/browser and added parity coverage. Removed old unsupported-error expectations and validated nested has/has_not assertion behavior in existing parity suites.
