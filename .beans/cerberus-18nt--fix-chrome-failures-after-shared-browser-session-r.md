---
# cerberus-18nt
title: Fix chrome failures after shared-browser-session rollout
status: in-progress
type: bug
priority: normal
created_at: 2026-03-03T11:03:49Z
updated_at: 2026-03-03T11:12:44Z
---

Investigate and fix newly observed Chrome failures/flakiness after shared browser session conversion.\n\nScope:\n- [x] Reproduce failing Chrome tests and identify failure clusters\n- [x] Patch tests/helpers to restore deterministic isolation where needed\n- [x] Run targeted + full browser validation\n- [ ] Commit code + bean
