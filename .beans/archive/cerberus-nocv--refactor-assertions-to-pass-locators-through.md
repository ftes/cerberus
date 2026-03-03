---
# cerberus-nocv
title: Refactor Assertions to pass locators through
status: completed
type: task
priority: normal
created_at: 2026-03-03T08:36:58Z
updated_at: 2026-03-03T08:56:58Z
parent: cerberus-npb0
---

Remove operation-specific locator reject/rewrite in Assertions; keep only locator normalization plus shallow binary/regex shorthand conversion for form operations.

## Summary of Changes

- Removed action-specific locator reject/rewrite logic from `Cerberus.Assertions` for `click`, `fill_in`, `select`, `choose`, `check`, `uncheck`, `upload`, and `submit`.
- Kept locator normalization and selector merge behavior.
- Preserved shallow form-action shorthand conversion (`binary`/`regex` input -> label locator semantics) while allowing explicit locator structs/maps through unchanged.
- Kept assertion-only restrictions (`assert_has`/`refute_has`) unchanged.
