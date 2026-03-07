---
# cerberus-1lbf
title: Analyze slowest regular tests
status: completed
type: task
priority: normal
created_at: 2026-03-07T06:09:07Z
updated_at: 2026-03-07T06:11:09Z
---

Run the regular test suite with --slowest 20 and summarize the slowest non-slow tests.

## Todo
- [x] Run mix test --slowest 20 for regular tests
- [x] Summarize the slowest tests and any obvious patterns
- [x] Update the bean summary and complete it

## Summary of Changes
- Ran the regular suite with source .envrc and a random PORT using mix test --slowest 20.
- Identified the slowest non-slow tests as predominantly browser-only integration cases, especially browser session setup, multi-session/tab flows, screenshot/open_browser helpers, popup mode, iframe handling, timeout assertions, and negative-path diagnostics that wait for browser-side timeouts.
- Observed that Phoenix-side counterparts are usually low-millisecond, while browser variants commonly land in the 150-1000ms range and a few exceed 1.5-2.0s.
