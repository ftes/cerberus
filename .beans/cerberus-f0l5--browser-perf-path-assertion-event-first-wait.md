---
# cerberus-f0l5
title: 'Browser perf: path assertion event-first wait'
status: completed
type: task
priority: normal
created_at: 2026-03-01T16:05:52Z
updated_at: 2026-03-01T16:10:06Z
blocked_by:
    - cerberus-p4hx
---

Shift path assertions to event-first waiting based on browser readiness signals.

## Todo
- [x] Remove in-page interval polling for path assertions
- [x] Use runtime assertion signal loop for retries until deadline
- [x] Validate async navigate and redirect path tests

## Summary of Changes
- Replaced in-page polling path assertion expression with one-shot path evaluation through shared helper wrapper.
- Updated browser path assertion flow to retry by waiting on runtime assertion signals and readiness until deadline, including navigation-transition eval errors.
- Verified async navigate and redirect path scenarios using browser timeout assertions and current_path tests under direnv.
