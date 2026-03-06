---
# cerberus-m5rl
title: Remove link/button locator kinds and switch to role-based locators
status: completed
type: feature
priority: normal
created_at: 2026-03-06T08:32:54Z
updated_at: 2026-03-06T08:41:57Z
---

## Goal
Remove dedicated :link/:button locator kinds and use role-based locators for clickable controls.

## Todo
- [x] Refactor locator normalization and action shape inference to role-based kinds
- [x] Update docs to use role-based locator helpers/sigil patterns
- [x] Update tests to remove link/button kind expectations and usage
- [x] Run format and targeted tests with randomized PORT
- [x] Add summary and complete bean

## Summary of Changes
Removed dedicated :link/:button locator kinds from normalization and leaf-kind typing. Removed public link()/button() locator helper APIs and migrated in-repo usage to role(:link/:button, name: ...). Updated live-driver simple-link ambiguity detection to treat role(:link, ...) as the simple-link shape. Updated README/getting-started/cheatsheet examples and broad test coverage to role-based locators only. Ran mix format and targeted tests with randomized ports: PORT=4127 (locator/helper/docs tests) and PORT=4138 (locator parity + link navigation/browser link semantics).
