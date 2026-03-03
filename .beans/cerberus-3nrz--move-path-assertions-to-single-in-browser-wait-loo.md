---
# cerberus-3nrz
title: Move path assertions to single in-browser wait loop
status: completed
type: task
priority: normal
created_at: 2026-03-03T11:30:52Z
updated_at: 2026-03-03T22:22:02Z
parent: cerberus-dsr0
---

Replace Elixir recursive orchestration for browser path assertions with one browser-side polling loop per assertion call.

Scope:
- [x] Use a single in-browser wait loop for browser assert_path and refute_path evaluation.
- [x] Keep exact, query, and regex matching semantics in browser path checks.
- [x] Keep path assertion diagnostics and timeout metadata aligned with common error formatting.
- [x] Validate behavior on chrome browser suites.

## Summary of Changes
- Browser path assertions now run through one browser helper path loop instead of Elixir-side recursion.
- The path loop computes path_match and query_match and returns timeout-aware observed values.
- Browser helper fallback path logic was kept consistent with expected path and query matching behavior.
