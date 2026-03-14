---
# cerberus-40f8
title: Investigate EV2 slowest Cerberus files
status: in-progress
type: task
priority: normal
created_at: 2026-03-14T21:21:45Z
updated_at: 2026-03-14T21:34:47Z
---

Use the new EV2 compare harness to take the slowest Cerberus files one by one, form a concrete hypothesis, reproduce the slowdown in Cerberus where possible, fix it, and verify the improvement back in ev2-copy.

## Current slice

- [x] Identify slowest EV2 Cerberus files from the sequential compare harness
- [x] Profile a representative slow test in document_controller_cerberus_test
- [ ] Reproduce the browser submit-button navigation slowdown in Cerberus
- [ ] Simplify browser post-action navigation handling while fixing the slowdown
- [ ] Verify the fix in the Cerberus suite and back in ev2-copy

## Progress notes

- Reproduced a browser delayed-submit navigation gap in Cerberus with a focused browser settle test.
- Fixed browser post-action await classification so deferred non-live submit-button clicks get a small grace window before readiness.
- Verified the Cerberus repro and cut EV2 document_controller_cerberus_test from about 107s per file to 19.4s at --max-cases 4.
