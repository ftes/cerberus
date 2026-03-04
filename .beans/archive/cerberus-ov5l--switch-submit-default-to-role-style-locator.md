---
# cerberus-ov5l
title: Switch submit default to role-style locator
status: completed
type: task
priority: normal
created_at: 2026-03-04T06:59:29Z
updated_at: 2026-03-04T07:00:46Z
---

Align submit default target selection away from CSS default selector and use role-style locator semantics.

- [x] Replace submit/1 default locator from CSS selector to role/button-style locator
- [x] Update docs/comments/tests wording if needed
- [x] Run format and targeted tests

## Summary of Changes

- Replaced `submit/1` default target from CSS selector (`css(@default_submit_selector)`) to role-style button locator (`button("")`).
- Removed the now-unused `@default_submit_selector` constant from `lib/cerberus.ex`.
- Verified with targeted tests: `form_actions_test.exs`, `form_button_ownership_test.exs`, and `live_form_change_behavior_test.exs`.
