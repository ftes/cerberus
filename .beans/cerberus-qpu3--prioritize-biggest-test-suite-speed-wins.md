---
# cerberus-qpu3
title: Prioritize biggest test-suite speed wins
status: completed
type: task
priority: normal
created_at: 2026-03-03T15:00:50Z
updated_at: 2026-03-03T15:03:39Z
---

Analyze slowest tests and propose highest-impact performance improvements with concrete implementation steps.

## Summary of Changes
- Ranked slowest costs from provided output: locator parity corpus test (~27.3s), two migration integration tests (~20.7s combined), and a cluster of browser integration tests in 1.6s to 3.0s range.
- Inspected top hotspots in:
  - test/cerberus/locator_parity_test.exs
  - test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs
  - test/cerberus/cross_driver_multi_tab_user_test.exs
  - test/cerberus/form_button_ownership_test.exs
  - test/cerberus/helper_locator_behavior_test.exs
  - test/cerberus/live_nested_scope_behavior_test.exs
  - test/cerberus/documentation_examples_test.exs
  - test/cerberus/live_form_synchronization_behavior_test.exs
  - test/cerberus/browser_extensions_test.exs
- Identified highest-value wins:
  1) Split/retag heavyweight integration tests (migration task suite + parity oracle) out of default loop.
  2) Eliminate timeout waits in expected-failure browser assertions/actions (use zero/low timeout where failures are intentional).
  3) Reuse browser sessions in heavy modules that still call session(:browser) per test.
  4) Reduce external mix-invocation overhead in migration tests via shared MIX_DEPS_PATH/MIX_BUILD_PATH and one-time deps bootstrap.
- Estimated impact: first two items alone remove most of the top-10 runtime share; session reuse + timeout tightening remove additional multi-second tails across many browser modules.
