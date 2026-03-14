---
# cerberus-uxc1
title: Fix remaining Firefox browser assertion and iframe failures
status: in-progress
type: bug
priority: normal
created_at: 2026-03-14T20:33:10Z
updated_at: 2026-03-14T20:34:53Z
---

Reproduce and fix the remaining Firefox-lane failures in value assertions and cross-origin iframe tests, rerun focused coverage, and summarize the root causes.

## Notes
- the reported Firefox failures did not reproduce in focused runs for test/cerberus/value_assertions_test.exs or test/cerberus/browser_iframe_limitations_test.exs, which points to full-suite pressure rather than a deterministic single-test break
- hardened the delayed browser value assertion by increasing its timeout to 2000ms and converted the iframe limitation module to a shared browser session with async false to avoid per-test browser startup and cross-origin navigation pressure under full-suite concurrency
