---
# cerberus-26bv
title: Deduplicate action candidate logic between action_helpers and expressions
status: completed
type: task
priority: normal
created_at: 2026-03-03T11:32:12Z
updated_at: 2026-03-03T18:55:43Z
parent: cerberus-dsr0
---

Remove drift risk by defining one canonical candidate resolution and execution contract for browser actions.\n\nScope:\n- [x] Remove duplicated candidate filtering and target selection logic across action_helpers.ex and expressions wrappers.\n- [x] Keep one canonical helper API used by all action entrypoints.\n- [x] Add tests that fail on semantic drift for candidate selection and target picking.

## Summary of Changes
- Removed legacy expression-wrapper action candidate resolution and target picking code from the browser driver.
- Routed click, submit, fill_in, select, choose, check, uncheck, and upload through the single canonical in-browser action helper pipeline.
- Deleted unused snapshot action helpers and related matching/filtering utilities to avoid future semantic drift.
- Added cross-driver regression coverage asserting deterministic first and last target picking for shared action locators.
