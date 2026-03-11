---
# cerberus-fpz0
title: Default live clicks to metadata dispatch and document portal support
status: completed
type: task
priority: normal
created_at: 2026-03-11T08:18:45Z
updated_at: 2026-03-11T08:21:08Z
---

## Goal

Make live-driver clicks prefer metadata-based dispatch by default and document current portal support limits.

## Todo

- [x] Inspect current click tests and docs for driver behavior notes
- [x] Switch live button click dispatch to prefer metadata path
- [x] Update docs to mention portal click-only support
- [x] Run targeted tests for live clicks and portals

## Summary of Changes

- Switched live button clicks to prefer metadata-based dispatch first, with selector-based `LiveViewTest.element/3` dispatch retained as a fallback.
- Kept the earlier portal click support working under the same metadata path, rather than as a portal-only special case.
- Documented current portal support in the README, fixture surface, and `click/3` docs: portal-backed button clicks are supported, while broader portal interactions still favor browser mode.
- Verified with `PORT=4134 mix test test/cerberus/live_portal_parity_test.exs`, `PORT=4135 mix test test/cerberus/live_click_bindings_behavior_test.exs`, `PORT=4136 mix test test/cerberus/form_actions_test.exs`, and `PORT=4137 mix test test/cerberus/helper_locator_behavior_test.exs` after sourcing `.envrc`.

## Remaining Gaps

- Metadata-first dispatch is implemented for live buttons. Live links, portal forms, and full portal DOM materialization are still follow-up work if we want portal parity beyond clicks.
