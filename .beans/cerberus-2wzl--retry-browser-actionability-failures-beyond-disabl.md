---
# cerberus-2wzl
title: Retry browser actionability failures beyond disabled state
status: completed
type: bug
priority: normal
created_at: 2026-03-12T08:44:35Z
updated_at: 2026-03-12T08:47:42Z
---

Fix the browser action loop so action functions can wait for transient actionability failures like delayed visibility, and add real tests under test/cerberus.

- [x] inspect existing browser action retry path and choose retryable failures
- [x] implement browser action retry for transient actionability failures
- [x] add non-tmp regression tests for browser visibility waits
- [x] run targeted browser suites and summarize

## Summary of Changes

Expanded the browser action retry classifier so browser actions retry transient `target_not_visible` and `target_detached` failures in addition to delayed disabled-state failures. Added real regression coverage in the browser extensions suite for delayed-visibility `click` and `fill_in`. Verified with targeted suites and the full `MIX_ENV=test mix do format + precommit + test` gate.
