---
# cerberus-23wd
title: Document tmp_dir concurrent-run flake risk in screenshot tests
status: completed
type: task
priority: normal
created_at: 2026-03-01T20:14:38Z
updated_at: 2026-03-01T20:14:45Z
---

Add explicit comments in screenshot tests that use @tag :tmp_dir to explain deterministic path behavior and potential flakes when multiple mix test processes run in same checkout.

## Summary of Changes
- Restored @tag :tmp_dir usage for screenshot path tests in test/cerberus/browser_test.exs and test/cerberus/cerberus_test/browser_extensions_test.exs.
- Added comments above the deterministic tmp_dir path usage explaining potential cross-process flakes when multiple mix test processes run against one checkout.
- Attempted validation was blocked by an unrelated compile error in lib/cerberus/options.ex in the current workspace state.
