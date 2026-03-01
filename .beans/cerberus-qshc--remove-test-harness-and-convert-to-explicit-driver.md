---
# cerberus-qshc
title: Remove test harness and convert to explicit driver loops
status: in-progress
type: task
priority: normal
created_at: 2026-03-01T17:33:28Z
updated_at: 2026-03-01T17:40:25Z
parent: cerberus-whq9
---

Phase 3: Replace Harness.run/run! usage with plain ExUnit patterns.

Goals:
- Remove test/support/harness.ex and related tag-driven matrix behavior.
- Use explicit for driver in ... loops where multi-driver coverage is needed.

## Todo
- [ ] Inventory and replace all Harness.run/run! call sites
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
