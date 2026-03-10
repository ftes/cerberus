---
# cerberus-eu4x
title: Skip unmatched original EV2 tests for fair performance comparison
status: completed
type: task
priority: normal
created_at: 2026-03-10T17:09:39Z
updated_at: 2026-03-10T17:13:16Z
---

Mark the remaining old-only EV2 tests as skipped where no Cerberus counterpart exists, so preserved original vs Cerberus runtime comparisons are apples-to-apples.

## Summary of Changes

- Marked the remaining unmatched original-only coverage in /Users/ftes/src/ev2-copy/test/ev2_web/controllers/user_controller_test.exs as skipped so the preserved original comparison lane no longer includes tests without a Cerberus counterpart.
- Used explicit @tag :skip for the three top-level user creation page tests and @describetag :skip inside the unmatched describe blocks.
- Kept the original PhoenixTest security-page parity test active.
- Re-ran the preserved original vs Cerberus comparison sets after the trim.
- Updated comparison totals:
  - Originals: 175 tests, 0 failures, 22 skipped, 26.8s
  - Cerberus: 155 tests, 0 failures, 4 skipped, 69.6s
