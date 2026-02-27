---
# cerberus-tcm3
title: Prepare package metadata and docs config
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:03:52Z
updated_at: 2026-02-27T11:05:39Z
---

Add publishing-related config in mix.exs.

## Todo
- [x] Add :ex_doc dependency (dev-only)
- [x] Add docs() function
- [x] Add package() function
- [x] Verify formatting/tests for changed file

## Summary of Changes
- Added ex_doc dependency (dev-only, runtime false).
- Added docs: docs() and package: package() to project metadata.
- Implemented docs/0 and package/0 helper functions in mix.exs.
- Verified with mix format --check-formatted mix.exs and mix test (23 tests, 0 failures).

- Ran mix deps.get to lock ex_doc and its transitive documentation dependencies in mix.lock.
