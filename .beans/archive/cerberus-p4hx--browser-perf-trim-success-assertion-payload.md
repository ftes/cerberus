---
# cerberus-p4hx
title: 'Browser perf: trim success assertion payload'
status: completed
type: task
priority: normal
created_at: 2026-03-01T16:05:52Z
updated_at: 2026-03-01T16:09:57Z
blocked_by:
    - cerberus-7pmn
---

Reduce browser assertion payload overhead on success.

## Todo
- [x] Return compact success payload for text assertions
- [x] Keep full diagnostics on failure and preserve error formatting
- [x] Validate no API or test regressions

## Summary of Changes
- Changed browser text assertion success completion to return compact payload from fast checks instead of full texts and matched arrays.
- Kept full diagnostic payload collection only for failure and timeout paths, preserving error message quality while reducing success-path overhead.
- Verified behavior using browser timeout, cross-driver text, and current_path tests.
