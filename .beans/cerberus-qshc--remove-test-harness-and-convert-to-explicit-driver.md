---
# cerberus-qshc
title: Remove test harness and convert to explicit driver loops
status: in-progress
type: task
priority: normal
created_at: 2026-03-01T17:33:28Z
updated_at: 2026-03-01T18:37:36Z
parent: cerberus-whq9
---

Phase 3: Replace Harness.run/run! usage with plain ExUnit patterns.

Goals:
- Remove test/support/harness.ex and related tag-driven matrix behavior.
- Use explicit for driver in ... loops where multi-driver coverage is needed.

## Todo
- [x] Inventory and replace all Harness.run/run! call sites
- [ ] Convert cross-driver scenarios to explicit loop-generated tests
- [ ] Remove harness support code and obsolete tags
- [ ] Run format and precommit

## Progress Notes
- Converted first representative file from Harness.run/run! to explicit driver loops: test/cerberus/core/select_choose_behavior_test.exs.
- Replaced context-tag matrix usage with compile-time for driver in [:phoenix, :browser] test generation and direct session(driver) calls.
- Validation: file-level run passed with CERBERUS_BROWSER_NAME=firefox (18 tests, 0 failures).
- Validation caveat: chrome lane currently flakes locally during session startup (Chrome instance exited), so chrome verification remains environment-flaky.

- Consolidated select_choose_behavior_test.exs into a single top-level for driver in [:phoenix, :browser] loop for all tests sharing the same driver set.
- Updated test bodies to call session(unquote(driver)) directly.
- Revalidated with firefox lane: 18 tests, 0 failures.

- Converted additional core test modules from Harness.run!/run to direct sessions and compile-time driver loops in test/cerberus/core:
  - browser_tag_showcase_test.exs
  - browser_timeout_assertions_test.exs
  - checkbox_array_behavior_test.exs
  - cross_driver_text_test.exs
  - live_navigation_test.exs
  - live_timeout_assertions_test.exs
  - live_visibility_assertions_test.exs
  - open_browser_behavior_test.exs
  - static_navigation_test.exs
  - static_upload_behavior_test.exs
- Kept non-browser public API constrained to session()/session(:phoenix); explicit :static/:live public aliases were not introduced.
- Preserved live default assertion-timeout semantics (500ms) when phoenix sessions transition into LiveView mode.
- Tightened shared assertion timeout resolution so static sessions remain fail-fast by default (timeout 0) unless explicitly overridden per call.

- Converted another harness-removal batch in test/cerberus/core:
  - current_path_test.exs
  - path_scope_behavior_test.exs
  - parity_mismatch_fixture_test.exs
  - cross_driver_multi_tab_user_test.exs
  - live_click_bindings_behavior_test.exs
- Replaced Harness.run!/run contexts with direct session(driver) flows using explicit `for driver <- [:phoenix, :browser]` loops where applicable.
- Validation: targeted chrome batch run passed (25 tests, 0 failures) and mix precommit passed.
