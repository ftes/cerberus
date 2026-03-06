---
# cerberus-uc6i
title: Hide observed payload in assertion errors
status: completed
type: task
priority: normal
created_at: 2026-03-04T08:40:14Z
updated_at: 2026-03-04T08:42:43Z
---

Remove internal observed payload from raised assertion messages while keeping candidate hints.

- [x] Remove observed line from assertion error formatter
- [x] Update README failure diagnostic example
- [x] Run format + focused tests
- [x] Update bean summary and mark completed

## Summary of Changes
- Removed the  line from  so raised assertion errors no longer expose the raw internal payload.
- Kept  output unchanged for actionable diagnostics.
- Updated README failure diagnostics example to remove the  line.
- Ran  and Running ExUnit with seed: 8657, max_cases: 28
Excluding tags: [slow: true]

.....
Finished in 0.01 seconds (0.01s async, 0.00s sync)
5 tests, 0 failures.
- Browser-inclusive focused suites failed in this environment because Chrome runtime bootstrap is broken ( framework binary missing).

## Summary of Changes (Corrected)
- Removed the observed line from assertion failure messages so internal payload details are not printed by default.
- Kept possible candidates output unchanged for actionable diagnostics.
- Updated README failure diagnostics example to match the new message shape.
- Ran format on the touched formatter file.
- Ran focused tests with environment loaded and confirmed passing result: 19 tests, 0 failures.
