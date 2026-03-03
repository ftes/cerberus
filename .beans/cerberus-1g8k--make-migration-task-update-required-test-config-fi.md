---
# cerberus-1g8k
title: Make migration task update required test config files
status: in-progress
type: task
priority: normal
created_at: 2026-03-03T16:01:12Z
updated_at: 2026-03-03T16:25:51Z
---

## Goal
Make mix cerberus.migrate_phoenix_test a one-stop migration step by updating required setup in config/test.exs and test/test_helper.exs.

## Todo
- [ ] Identify required Cerberus config/test helper bootstrap lines
- [ ] Implement migration task rewrites for config/test.exs and test/test_helper.exs
- [ ] Add/extend migration task tests for config/test helper updates
- [ ] Run format and targeted tests

## Notes\n- Added a post-migration fixture test run assertion in migration integration test.\n- Post-migration run currently fails for many  rows, confirming migration API gaps are real and were previously hidden because only pre-migration + rewrite success were asserted.

## Progress (API alignment)\n- Updated migration rewrite canonicalization to emit current Cerberus forms: scoped string selectors are wrapped as css(...) / Cerberus.css(...), and within("...", fn -> ...) is rewritten to within(css("..."), fn -> ...).\n- Stopped rewriting select(..., option: ...) to outdated positional select(..., value) form.\n- Added explicit post-migration fixture test execution assertion in slow migration integration test, so before+after runs are enforced.\n- Extended migration invocation in that integration test to include support files needed by migrated tests.\n- Added static-driver fallback for click_button on submit-capable buttons by reusing submit path, preserving common migrated PhoenixTest form flows.\n- Re-baselined migration task tests to assert modern rewritten output (css-wrapped scoped assertions and keyword select option).\n- Verified with mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs --include slow (pass).
