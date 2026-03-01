---
# cerberus-19ic
title: Audit locator parity across drivers
status: completed
type: task
priority: normal
created_at: 2026-03-01T15:52:38Z
updated_at: 2026-03-01T15:54:04Z
---

Assess current locator support in Static, Live, and Browser drivers and identify gaps vs Capybara/Playwright.

## Todo
- [x] Inspect locator model and parsing
- [x] Inspect Static/Live/Browser locator handling paths
- [x] Compare implemented surface with Capybara/Playwright locator capabilities
- [x] Summarize supported features and concrete gaps

## Summary of Changes
- Audited locator normalization and helper APIs in `Cerberus.Locator`, `Cerberus.Assertions`, and `Cerberus` public helpers.
- Audited locator execution paths for Static, Live, and Browser drivers, including Browser JS-side matching/evaluation.
- Confirmed current parity is designed around a constrained "slice" and identified explicit unsupported areas.
- Compiled concrete feature-gap list relative to Capybara and Playwright locator systems.
