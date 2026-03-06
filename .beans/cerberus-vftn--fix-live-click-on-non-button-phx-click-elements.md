---
# cerberus-vftn
title: Fix live click on non-button phx-click elements
status: completed
type: bug
priority: normal
created_at: 2026-03-04T21:06:52Z
updated_at: 2026-03-06T20:16:46Z
---

## Goal
Fix ev2 EmailsLiveTest failure where click reports no clickable element even though the asserted td text exists.

## Tasks
- [x] Reproduce failing ev2 test and capture failing locator + candidate details
- [x] Verify live click matcher supports non-button phx-click elements
- [x] Add Cerberus regression test for non-button phx-click clickability
- [x] Implement fix and verify in cerberus + ev2 targeted tests

## Summary of Changes
- Added regression coverage for clicking non-button phx-click elements in live views.
- Verified the live click fix against focused Cerberus and EV2 targeted tests.
