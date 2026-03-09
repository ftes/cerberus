---
# cerberus-9pt7
title: Trim browser candidate-hint failure test runtime
status: completed
type: task
priority: normal
created_at: 2026-03-09T15:22:56Z
updated_at: 2026-03-09T15:34:07Z
---

## Goal

Reduce the runtime of the browser candidate-hint failure coverage in form_actions_test without weakening the asserted error shape.

## Tasks

- [x] Inspect the current negative-path assertions and identify avoidable timeout budget
- [x] Tighten the browser failure assertions while preserving candidate-hint checks
- [x] Re-run targeted tests and the unified full gate
- [x] Summarize the updated top regular outliers

## Summary of Changes

Tightened the browser negative-path coverage in form_actions_test by reusing one visited session and cutting browser-only failure timeouts to 50ms. The browser candidate-hint row dropped from roughly 1.3s to about 0.24-0.27s while preserving the same possible-candidates assertions. Verified with targeted reruns and the unified mix do format + precommit + test gate.
