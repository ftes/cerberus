---
# cerberus-xwqt
title: Implement active-form submit(session) semantics across drivers
status: completed
type: task
priority: normal
created_at: 2026-03-04T07:10:30Z
updated_at: 2026-03-04T07:27:20Z
---

Align submit(session) with PhoenixTest semantics across static/live/browser: use active form, and fail when no active form exists.

- [x] Implement submit(session) active-form semantics in Cerberus facade and drivers
- [x] Ensure browser driver can resolve active form submit target reliably
- [x] Add parity tests for active-form submit success and no-active-form failure across drivers
- [x] Run format and targeted tests

## Summary of Changes
- Added dedicated submit_active_form driver callback and switched Cerberus.submit/1 to use active-form semantics.
- Implemented active-form submit handling in static/live/browser drivers, including explicit failure when no active form exists.
- Tracked active form selectors in static/live form-data and browser action targets so forms without ids are still supported.
- Added parity coverage for submit/1 on static and live routes (phoenix + browser) and no-active-form failure assertions.
- Verified with mix format and targeted tests for form actions + live trigger-action behavior.
