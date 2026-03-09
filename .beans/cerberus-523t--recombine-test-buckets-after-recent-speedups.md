---
# cerberus-523t
title: Recombine test buckets after recent speedups
status: completed
type: task
priority: normal
created_at: 2026-03-09T15:02:16Z
updated_at: 2026-03-09T15:08:44Z
---

## Goal

Collapse the regular/slow split where the recent test-speed work made it unnecessary.

## Tasks

- [ ] Re-measure the current slowest regular and slow rows
- [ ] Move tests back out of :slow where the regular lane stays healthy
- [ ] Re-run regular and slow suites to confirm the bucket balance
- [x] Summarize the new slowest tests and remaining bucket rationale

## Summary of Changes

Moved five leftover medium-cost browser rows back out of the slow bucket:

- cross_driver_multi_tab_user_test browser parity row
- documentation_examples multi-user browser parity row
- value_assertions missing-field browser row
- form_actions possible-candidate browser row
- live_select_regression browser multi-select row

Re-ran the regular and slow lanes at max_cases 28.

Current totals:

- regular lane: 564 tests, 0 failures, 4 skipped in 44.1s
- slow lane: 29 tests, 0 failures in 13.0s

Remaining slow coverage is now concentrated on the intentionally expensive rows: popup and multi-session browser semantics, readiness timeout fixtures, explicit slow_mo coverage, and the heavy locator parity/browser extension corpora.
