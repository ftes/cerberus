---
# cerberus-kwhu
title: Audit missing browser parity coverage
status: completed
type: task
priority: normal
created_at: 2026-03-03T22:07:11Z
updated_at: 2026-03-03T22:07:16Z
---

Identify tests that currently exercise only phoenix live/static behavior and should likely run with browser parity coverage.

## Summary of Changes

- Audited test/cerberus integration suites for files that only run on :phoenix and compared against existing cross-driver parity suites.
- Identified high-signal parity gaps: live timeout transitions, live visibility filters, static upload flow, and static navigation/redirect flow.
- Confirmed explicit_browser and profiling suites are intentionally single-driver and not parity targets.
