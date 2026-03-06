---
# cerberus-t0qq
title: Remove two-locator click API and collapse migration output
status: completed
type: feature
priority: normal
created_at: 2026-03-04T21:05:57Z
updated_at: 2026-03-04T21:11:48Z
---

Cleanly remove click(session, scope, locator) API. Keep single-locator click only. Update migration task so click_link/click_button rewrites that previously relied on two-locator click collapse into one locator expression. Simplify code/tests/docs accordingly.

\n## Summary of Changes\n- Removed two-locator click API from Cerberus public facade. click now only supports click(session, locator) and click(session, locator, opts).\n- Deleted click argument disambiguation helpers that existed only for scoped click overload handling.\n- Updated within closest behavior test to use within plus click instead of the removed scoped click overload.\n- Updated migration canonicalization to handle click_link/click_button source calls that carried scope plus locator, collapsing them into single-locator click calls using link(scope, locator) or button(scope, locator).\n- Simplified migration locator index rules by dropping click-specific scoped-arg handling now that scoped click is removed.\n- Added migration regression coverage for scoped click_link/click_button rewrite collapse.\n\n## Verification\n- source .envrc and PORT=4726 mix test test/cerberus/within_closest_behavior_test.exs test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs\n- source .envrc and PORT=4738 mix test test/mix/tasks/igniter_cerberus_migrate_phoenix_test_test.exs --include slow --only slow
