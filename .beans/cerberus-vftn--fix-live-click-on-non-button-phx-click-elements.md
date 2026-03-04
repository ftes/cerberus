---
# cerberus-vftn
title: Fix live click on non-button phx-click elements
status: in-progress
type: bug
priority: normal
created_at: 2026-03-04T21:06:52Z
updated_at: 2026-03-04T21:26:35Z
---

## Goal
Fix ev2 EmailsLiveTest failure where click reports no clickable element even though the asserted td text exists.

## Tasks
- [x] Reproduce failing ev2 test and capture failing locator + candidate details
- [x] Verify live click matcher supports non-button phx-click elements
- [x] Add Cerberus regression test for non-button phx-click clickability
- [ ] Implement fix and verify in cerberus + ev2 targeted tests
