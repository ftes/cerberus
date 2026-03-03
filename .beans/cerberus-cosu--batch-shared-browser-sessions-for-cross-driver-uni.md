---
# cerberus-cosu
title: Batch shared browser sessions for cross-driver unit tests
status: completed
type: task
priority: normal
created_at: 2026-03-03T10:25:31Z
updated_at: 2026-03-03T10:27:19Z
---

Apply shared browser-session reuse to additional high-impact, low-risk cross-driver unit-style tests to reduce per-test browser startup overhead.\n\nScope:\n- [x] Convert select_choose_behavior_test to shared browser session pattern\n- [x] Convert live_trigger_action_behavior_test to shared browser session pattern\n- [x] Convert path_scope_behavior_test to shared browser session pattern\n- [x] Run format + focused suites + precommit\n- [x] Commit code + bean

## Summary of Changes

Applied shared browser-session reuse to three high-impact cross-driver unit-style modules to reduce per-test browser startup overhead while preserving existing assertions and Phoenix-lane behavior.

Updated modules:
- test/cerberus/select_choose_behavior_test.exs
- test/cerberus/live_trigger_action_behavior_test.exs
- test/cerberus/path_scope_behavior_test.exs

Pattern applied:
- Added module-level `setup_all` that starts one browser session in a dedicated owner process.
- Replaced per-test `session(:browser)` construction with `driver_session(:browser, context)`.
- Kept `driver_session(:phoenix, _context)` as fresh per-test `session(:phoenix)`.
- Added deterministic teardown of the owner process via `on_exit`.

Validation:
- source .envrc && mix format
- source .envrc && mix test test/cerberus/select_choose_behavior_test.exs test/cerberus/live_trigger_action_behavior_test.exs test/cerberus/path_scope_behavior_test.exs
- source .envrc && mix precommit
