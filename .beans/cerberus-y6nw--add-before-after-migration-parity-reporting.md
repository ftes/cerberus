---
# cerberus-y6nw
title: Add before-after migration parity reporting
status: completed
type: task
priority: normal
created_at: 2026-02-28T08:47:02Z
updated_at: 2026-02-28T13:59:15Z
parent: cerberus-it5x
---

Record and assert before/after test pass results with clear row-level parity reporting against the migration matrix.

## Summary of Changes
- Extended Cerberus.MigrationVerification with row-based execution and parity reporting.
- Added report output with row-level pre/post status, parity flag, and aggregate summary counts.
- Added failure payload reporting that includes row_id/test_file and partial parity report state.
- Added ExUnit coverage for single-row success, multi-row parity reporting, and post-stage failure report semantics.
