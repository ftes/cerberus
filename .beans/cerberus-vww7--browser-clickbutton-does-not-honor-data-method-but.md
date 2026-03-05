---
# cerberus-vww7
title: Browser click(button) does not honor data-method button navigation
status: completed
type: bug
priority: normal
created_at: 2026-03-05T19:52:36Z
updated_at: 2026-03-05T19:56:37Z
parent: cerberus-zh82
---

## Problem
Browser driver does not execute data-method form submission semantics for non-form buttons with data-method/data-to attributes.

## Reproduction
1. Start a browser session.
2. Visit /phoenix_test/page/index.
3. click(button("Data-method Delete")).
4. Expected to navigate and render Record deleted page.
5. Actual stays on /phoenix_test/page/index and assert_has(h1: Record deleted) fails.

## Evidence
- test/cerberus/data_method_click_behavior_test.exs: browser case fails while static/live variants pass.

## Plan
Inspect browser click(button) path and add data-method handling parity with static/live driver behavior.

## Summary of Changes
- Fixed browser-driver handling for data-method actions on click targets.
- Updated browser action helper candidate metadata to include dataMethod/dataTo/dataCsrf for link/button targets.
- Added helper.submitDataMethod() to emulate method-form navigation (including _method override and csrf token injection).
- Used document meta csrf-token preferentially for browser submissions to avoid invalid fixture token issues.
- Added browser error mapping for missing data-method target to keep parity with static/live contract wording.
- Verified via first-class browser regression test:
  - PORT=4357 mix test test/cerberus/data_method_click_behavior_test.exs (includes browser lane)
  - plus PORT=4359 mix test test/cerberus/input_submit_button_behavior_test.exs.
