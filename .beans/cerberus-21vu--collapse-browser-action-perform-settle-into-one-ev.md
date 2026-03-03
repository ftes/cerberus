---
# cerberus-21vu
title: Collapse browser action perform + settle into one eval
status: completed
type: task
priority: normal
created_at: 2026-03-03T14:28:58Z
updated_at: 2026-03-03T14:40:23Z
---

Goal: move post-action settle into action helper execution so non-navigation actions avoid a second Elixir roundtrip.

## Todo
- [x] Implement post-action settle wait in action helper JS
- [x] Return settle metadata/timing in action helper payload
- [x] Wire Elixir action flow to consume settle metadata
- [x] Add/adjust tests and run profiling subset to verify reduced await_ready pressure

## Summary of Changes
- Extended browser action helper JS with in-eval live settle waiting and emitted settle metadata on successful actions.
- Added actionPostSettleMs timing so settle overhead is tracked in jsTiming payloads.
- Added needsAwaitReady decisions in helper results and consumed them in browser click and submit flow to skip extra Elixir await_ready only when safe.
- Added safety guard to always await link clicks and avoid post-action settle probing for link targets to prevent navigation races.
- Added browser behavior coverage in test/cerberus/browser_action_settle_behavior_test.exs and validated related browser flows with source .envrc && mix test test/cerberus/browser_action_settle_behavior_test.exs test/cerberus/form_actions_test.exs test/cerberus/live_form_synchronization_behavior_test.exs test/cerberus/live_link_navigation_test.exs.
