---
# cerberus-dznl
title: Trim next post-unskip runtime outliers
status: completed
type: task
priority: normal
created_at: 2026-03-09T17:03:21Z
updated_at: 2026-03-09T17:10:19Z
---

Re-baseline the fully unskipped suite with mix test --slowest 20, identify the next real runtime outliers, trim the best low-risk ones, and verify the full test gate.

## Progress Notes

Reused a shared browser session in cross_driver_text_test and live_select_regression_test, and tightened the immediate negative-path browser timeout in cross_driver_text_test. Verified the targeted files, then reran the full format + precommit + test gate and a unified mix test --slowest 20 baseline.



## Summary of Changes

Re-baselined the fully unskipped suite, then trimmed low-risk browser overhead by reusing a shared browser session in cross_driver_text_test, live_select_regression_test, and the no-button browser submit parity row in form_actions_test. Tightened the missing-text browser negative-path timeout in cross_driver_text_test. Verified with targeted runs, a unified slowest baseline, and the full format + precommit + test gate.
