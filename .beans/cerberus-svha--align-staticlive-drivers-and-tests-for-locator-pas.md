---
# cerberus-svha
title: Align static/live drivers and tests for locator pass-through
status: completed
type: task
priority: normal
created_at: 2026-03-03T08:36:58Z
updated_at: 2026-03-03T08:57:31Z
parent: cerberus-npb0
---

Update static/live drivers to accept unchanged locators and move kind interpretation to matcher layer; update tests/docs; run format and precommit.

## Summary of Changes

- Updated static/live/browser action entrypoints to accept generic `%Locator{}` and centralize locator-shape interpretation in `Cerberus.Driver.LocatorOps`.
- Added cross-driver `LocatorOps` helper for click/form/submit locator pass-through mapping (including CSS/testid handling).
- Updated parity and API tests to reflect pass-through behavior (explicit text locators accepted for form actions; invalid-locator expectations replaced with runtime matching errors).
- Verified with formatting, targeted test suites, and full `mix precommit`.
