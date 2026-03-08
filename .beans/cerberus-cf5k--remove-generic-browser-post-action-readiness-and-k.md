---
# cerberus-cf5k
title: Remove generic browser post-action readiness and keep only visit/navigation waits
status: completed
type: bug
priority: normal
created_at: 2026-03-08T08:46:46Z
updated_at: 2026-03-08T08:53:23Z
---

## Scope

- [x] Remove generic post-action readiness waits from Cerberus browser actions.
- [x] Keep visit readiness and only keep action-side waiting when the browser action actually navigates.
- [x] Update browser tests to stop asserting on click or submit readiness side effects.
- [x] Verify targeted Cerberus browser coverage and the hot EV2 browser sample.
- [x] Summarize the behavior change and results.

## Summary of Changes

- Removed generic browser post-action readiness waits from action execution. Browser actions now rely on actionability before the action and on the next action or assertion to wait for whatever state it needs.
- Kept visit readiness intact and limited action-side await-ready to click and submit results that already observed navigation.
- Updated browser readiness tests to assert the new no_post_action_wait behavior for non-navigation actions.
- Fixed the browser action preload helper version mismatch while touching the driver.
- Updated the README so the public behavior matches the implementation.
- Verified targeted Cerberus browser coverage and reran the EV2 project_form_feature Cerberus sample.
