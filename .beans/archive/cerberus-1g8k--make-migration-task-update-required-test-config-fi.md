---
# cerberus-1g8k
title: Make migration task update required test config files
status: completed
type: task
priority: normal
created_at: 2026-03-03T16:01:12Z
updated_at: 2026-03-03T17:03:50Z
---

## Goal
Make mix cerberus.migrate_phoenix_test a one-stop migration step by updating required setup in config/test.exs and test/test_helper.exs.

## Todo
- [x] Identify required Cerberus config/test helper bootstrap lines
- [x] Implement migration task rewrites for config/test.exs and test/test_helper.exs
- [x] Add/extend migration task tests for config/test helper updates
- [x] Run format and targeted tests

## Notes
- Added a post-migration fixture test run assertion in migration integration test.
- Post-migration run currently fails for many rows, confirming migration API gaps are real and were previously hidden because only pre-migration plus rewrite success were asserted.

## Progress (API alignment)
- Updated migration rewrite canonicalization to emit current Cerberus forms: scoped string selectors are wrapped as css(...) or Cerberus.css(...), and within("...", fn -> ...) is rewritten to within(css("..."), fn -> ...).
- Stopped rewriting select(..., option: ...) to outdated positional select(..., value) form.
- Added explicit post-migration fixture test execution assertion in slow migration integration test, so before and after runs are enforced.
- Extended migration invocation in that integration test to include support files needed by migrated tests.
- Added static-driver fallback for click_button on submit-capable buttons by reusing submit path, preserving common migrated PhoenixTest form flows.
- Re-baselined migration task tests to assert modern rewritten output (css-wrapped scoped assertions and keyword select option).
- Verified with mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs --include slow (pass).

## Summary of Changes
- Made migration target selection include setup files (config/test.exs and test/test_helper.exs) for default and relative path runs so migration is one-step.
- Added config rewrite support for config/test.exs: rewrite config :phoenix_test blocks to config :cerberus and append config :phoenix_test endpoint compatibility when needed.
- Added deterministic test/test_helper.exs endpoint bootstrap insertion: infer endpoint from neighboring config/test.exs and append Application.put_env(:cerberus, :endpoint, ...) without optional warnings.
- Added migration task tests covering config compatibility rewrite and test helper endpoint bootstrap insertion.
- Verified with mix format on changed files and mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs --include slow (pass).
