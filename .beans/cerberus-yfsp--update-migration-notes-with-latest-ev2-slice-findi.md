---
# cerberus-yfsp
title: Update migration notes with latest EV2 slice findings
status: completed
type: task
priority: normal
created_at: 2026-03-06T22:32:22Z
updated_at: 2026-03-06T22:32:44Z
---

Add the concrete migration findings from the latest EV2 slice to MIGRATE_FROM_PHOENIX_TEST.md. Focus on what would help on a second migration pass: disabled field assertions, stable post-submit success signals, regex assert_path exactness, and preserving structured locator semantics.

## Summary of Changes

Updated MIGRATE_FROM_PHOENIX_TEST.md with the latest EV2 migration findings:
- preserve structured locator semantics when they carry real intent
- use scoped field-container assertions for disabled/read-only field value checks when assert_value is the wrong fit
- prefer stable post-submit destination assertions over transient success toasts when navigation has already completed
- note that regex assert_path checks may need exact: false during migration debugging
