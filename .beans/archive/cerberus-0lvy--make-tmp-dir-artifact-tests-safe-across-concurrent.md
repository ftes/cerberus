---
# cerberus-0lvy
title: Make tmp_dir artifact tests safe across concurrent test runs
status: scrapped
type: bug
priority: normal
created_at: 2026-03-01T20:10:39Z
updated_at: 2026-03-01T20:14:33Z
---

Eliminate deterministic file-path collisions for tests using @tag :tmp_dir when multiple mix test processes run against the same workspace. Use per-run unique filenames for screenshot and other temporary artifacts, and validate impacted tests.

## Summary of Changes
- Removed deterministic ExUnit :tmp_dir screenshot paths from browser screenshot tests that were vulnerable to cross-process path cleanup collisions.
- Switched screenshot artifact paths to per-run random files under System.tmp_dir!() using cryptographically random suffixes.
- Updated test/cerberus/browser_test.exs and test/cerberus/cerberus_test/browser_extensions_test.exs accordingly.
- Validation: mix test --warnings-as-errors --exclude browser test/cerberus/browser_test.exs test/cerberus/cerberus_test/browser_extensions_test.exs passed.

## Reasons for Scrapping
- User requested to keep tmp_dir usage rather than moving artifact paths to run-unique locations.
- Implemented a documentation-only mitigation (code comments in affected tests) instead of behavioral isolation.
