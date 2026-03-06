---
# cerberus-qxx3
title: Fix browser visit readiness timeout on EV2 login/live reconnect flows
status: completed
type: bug
priority: normal
created_at: 2026-03-06T20:17:07Z
updated_at: 2026-03-06T20:26:14Z
---

## Goal

Fix Cerberus browser visit readiness so UI login and subsequent EV2 LiveView navigation do not fail with liveview-disconnected timeout.

## Todo

- [x] Inspect current browser visit readiness implementation and compare with simpler Playwright behavior
- [x] Add or adjust regression coverage for login/live reconnect style navigation
- [x] Simplify or correct browser readiness logic without regressing existing browser settle behavior
- [x] Run targeted tests in cerberus and EV2-copy with random PORT values
- [x] Summarize the behavioral change and remaining risks

## Summary of Changes

Simplified browser visit readiness in two ways: mixed connected/disconnected LiveView roots now count as connected if any root is connected, and visit-time readiness timeouts with a disconnected live state now recover when the navigated page can still be snapshotted.

Added regression fixtures and browser tests covering mixed live roots and disconnected-root visit recovery.

Verified targeted Cerberus browser tests and reran the previously failing EV2 browser test, which now passes through the UI login flow and follow-up visit.
