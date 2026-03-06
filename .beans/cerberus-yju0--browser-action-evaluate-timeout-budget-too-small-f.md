---
# cerberus-yju0
title: Browser action evaluate timeout budget too small for live waits
status: in-progress
type: bug
created_at: 2026-03-06T21:27:13Z
updated_at: 2026-03-06T21:27:13Z
---

## Goal

Fix browser action evaluation timing so LiveView actions that spend time waiting for connected state, action resolution, and post-action settle return a normal Cerberus action result instead of hitting a raw bidi command timeout.

## Todo

- [ ] Add a browser regression that reproduces a bidi timeout from combined live wait + action timeout budget
- [ ] Adjust browser action evaluation timeout budgeting to cover the full helper.perform lifecycle
- [ ] Run targeted Cerberus tests with random PORT and record results
- [ ] Re-run the affected EV2 create_offer slice and record outcomes
