---
# cerberus-7tku
title: Conditional await_ready for browser non-navigation actions
status: completed
type: task
priority: normal
created_at: 2026-03-03T14:28:58Z
updated_at: 2026-03-03T14:40:23Z
---

Goal: skip Elixir await_ready when browser action has already settled and navigation is not expected.

## Todo
- [x] Add action result metadata to signal whether await_ready is required
- [x] Update browser action result handlers to conditionally call await_driver_ready
- [x] Add coverage proving non-navigation browser actions can skip await_ready safely

## Summary of Changes
- Added action helper metadata (needsAwaitReady and settle) so browser actions can signal when post-action Elixir await_ready is still required.
- Updated browser click and submit result handlers to call await_driver_ready conditionally and use inline settle readiness when safe.
- Added browser behavior coverage in test/cerberus/browser_action_settle_behavior_test.exs to prove non-navigation live click and submit can skip await_ready.
- Kept navigation safe by requiring await_ready for link clicks and by skipping in-action settle probing for link targets.
- Verified changes with source .envrc && mix test test/cerberus/browser_action_settle_behavior_test.exs test/cerberus/form_actions_test.exs test/cerberus/live_form_synchronization_behavior_test.exs test/cerberus/live_link_navigation_test.exs and source .envrc && mix precommit.
