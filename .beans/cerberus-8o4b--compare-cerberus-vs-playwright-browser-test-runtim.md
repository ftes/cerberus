---
# cerberus-8o4b
title: Compare Cerberus vs Playwright browser-test runtime shape
status: completed
type: task
priority: normal
created_at: 2026-03-12T17:38:54Z
updated_at: 2026-03-13T08:27:13Z
---

Check whether Chrome browser tests in this repo are materially slower under Cerberus than under the original Playwright-backed tests, and identify the most likely sources of that overhead from the codebase and recent runs.

- [x] inspect browser test aliases and comparable test files
- [x] compare runtime shape between Cerberus and original browser tests
- [x] summarize likely sources of Cerberus browser overhead

## Summary of Changes

- Confirmed Cerberus browser hot paths still pay extra costs versus Playwright-style native locators: explicit readiness waits after navigation, DOM snapshot reparsing in `within/3`, and JS evaluation/retry layers around assertions and actions.
- Used that comparison to guide the CI instrumentation change toward collecting slowest tests plus profiling buckets, rather than guessing at transport cost.
