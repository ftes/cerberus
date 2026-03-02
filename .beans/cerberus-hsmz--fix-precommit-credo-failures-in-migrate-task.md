---
# cerberus-hsmz
title: Fix precommit Credo failures in migrate task
status: completed
type: bug
priority: normal
created_at: 2026-03-02T14:01:26Z
updated_at: 2026-03-02T14:05:11Z
---

Scope:
- [x] Refactor migrate task functions flagged by Credo nesting/complexity checks
- [x] Run mix format on touched files
- [x] Run mix precommit and confirm Credo issues are resolved
- [x] Add summary and mark completed

## Summary of Changes
- Refactored igniter reduce accumulation and migrate_file control flow to remove deep nesting while preserving behavior.
- Extracted helper functions for file update persistence and canonical argument rebuilding and merging to lower cyclomatic complexity in migration canonicalization helpers.
- Fixed docs warnings-as-errors by replacing hidden Cerberus.Driver.Browser.Types cookie reference with a public Cerberus.Browser cookie map type.
- Ran mix format and mix precommit; all checks pass.
