---
# cerberus-7pmn
title: 'Browser perf: text scan optimization'
status: completed
type: task
priority: normal
created_at: 2026-03-01T16:05:52Z
updated_at: 2026-03-01T16:09:51Z
---

Improve browser text assertion scan efficiency.

## Todo
- [x] Replace broad element expansion with TreeWalker text-node scanning where possible
- [x] Keep visible hidden selector scope semantics intact
- [x] Validate with browser text assertion tests

## Summary of Changes
- Reworked browser assertion scanning internals to use TreeWalker-based element traversal in shared assertion helpers instead of broad querySelectorAll star expansion.
- Preserved scope selector, element selector, and visible hidden semantics while reducing scan overhead and allocation pressure.
- Validated with browser text and timeout assertion tests under direnv-loaded env.
