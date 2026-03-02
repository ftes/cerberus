---
# cerberus-euh8
title: Refactor browser expressions normalization snippets (increment 4)
status: completed
type: task
priority: normal
created_at: 2026-03-02T06:43:27Z
updated_at: 2026-03-02T06:44:52Z
---

## Problem
expressions.ex repeats text normalization lambdas across multiple snippets.

## TODO
- [x] Extract shared normalization snippet helpers
- [x] Apply normalization helpers across relevant snippets
- [x] Run format and targeted tests
- [x] Run precommit
- [x] Add summary of changes

## Summary of Changes
- Added shared normalization helpers in expressions.ex:
  - normalize_trim_snippet/0 for trim-based text normalization.
  - normalize_collapsed_snippet/0 for whitespace-collapsing normalization.
- Replaced repeated inline normalize lambdas in snapshot/clickables/form_fields/file_fields/select_set with the shared snippets.
- Verified with mix format, targeted browser suites, and mix precommit.
