---
# cerberus-y1g5
title: Migrate first EV2 PhoenixTest cases to Cerberus
status: completed
type: task
priority: normal
created_at: 2026-03-06T07:59:06Z
updated_at: 2026-03-06T09:13:17Z
---

Migrate a small first batch of tests from ../ev2-copy into cerberus without shim compatibility.

- [x] Identify candidate non-browser and browser PhoenixTest cases in ../ev2-copy
- [x] Port selected non-browser cases to Cerberus tests using Ev2Web.ConnCase where appropriate
- [x] Port selected browser cases and set user_agent for sandbox in each browser test module
- [x] Run mix format and targeted tests with random PORT=4xxx after sourcing .envrc
- [x] Summarize migration and validation results

## Summary of Changes
- Added test support helper module test/support/cerberus.ex with browser session setup, sandbox user-agent metadata handling, and browser log_in/2 flow.
- Migrated first non-browser case test/ev2_web/controllers/info_controller_test.exs to Cerberus APIs under Ev2Web.ConnCase.
- Migrated first browser cases test/features/sidebar_search_test.exs, test/ev2_web/live/project_live/contacts_browser_test.exs, and test/ev2_web/live/user_live/preferences_form_test.exs to Cerberus browser sessions and login helper.
- Replaced link/button-style locators with role/sigil locators where possible in migrated tests.
- Verified with targeted run: direnv exec . env MIX_ENV=test PORT=4417 mix test --include integration:true test/features/sidebar_search_test.exs test/ev2_web/live/project_live/contacts_browser_test.exs test/ev2_web/live/user_live/preferences_form_test.exs test/ev2_web/controllers/info_controller_test.exs -> 7 tests, 0 failures.

## Follow-up: Cerbrerus Tagging
- [x] Add @moduletag :cerbrerus to migrated test modules
- [x] Run targeted tests with MIX_ENV=test and random PORT=4xxx

## Summary of Follow-up
- Added @moduletag :cerbrerus to all migrated test modules.
- Validation passed with MIX_ENV=test runs:
  - direnv exec . env MIX_ENV=test PORT=4293 mix test --include integration:true test/features/sidebar_search_test.exs test/ev2_web/live/project_live/contacts_browser_test.exs test/ev2_web/live/user_live/preferences_form_test.exs
  - direnv exec . env MIX_ENV=test PORT=4684 mix test test/ev2_web/controllers/info_controller_test.exs

## Follow-up: Cerberus Helper Simplification
- [x] Simplify test/support/cerberus.ex browser_session and remove conn/binary/live-connect helper complexity
- [x] Update migrated test modules for new helper API if needed
- [x] Run mix format and targeted tests with MIX_ENV=test and random PORT=4xxx

## Summary of Helper Simplification
- Simplified test/support/cerberus.ex to keep only browser_session/2 and log_in/2.
- Removed conn-sensitive sandbox branching, browser binary path overrides, and explicit await_lv_connect/visit_live helpers.
- browser_session/2 now sets user agent from Phoenix SQL sandbox metadata in current test process (metadata_for(self) + encode_metadata), avoiding the already-owner conflict under ConnCase.
- Validation passed:
  - direnv exec . env MIX_ENV=test PORT=4526 mix test --include integration:true test/features/sidebar_search_test.exs test/ev2_web/live/project_live/contacts_browser_test.exs test/ev2_web/live/user_live/preferences_form_test.exs
  - direnv exec . env MIX_ENV=test PORT=4742 mix test test/ev2_web/controllers/info_controller_test.exs

## Follow-up: Helper API Trim
- [x] Change browser_session to browser_session/1 (opts only)
- [x] Update migrated browser tests to call browser_session(opts)
- [x] Run targeted MIX_ENV=test runs with random PORT=4xxx

## Summary of Helper API Trim
- Changed helper API to browser_session/1 (opts-only) in test/support/cerberus.ex.
- Updated migrated browser tests to call browser_session(...) directly (no context piping).
- Validation passed:
  - direnv exec . env MIX_ENV=test PORT=4876 mix test --include integration:true test/features/sidebar_search_test.exs test/ev2_web/live/project_live/contacts_browser_test.exs test/ev2_web/live/user_live/preferences_form_test.exs
  - direnv exec . env MIX_ENV=test PORT=4913 mix test test/ev2_web/controllers/info_controller_test.exs
