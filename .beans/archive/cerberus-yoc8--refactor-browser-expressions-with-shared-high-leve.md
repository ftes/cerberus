---
# cerberus-yoc8
title: Refactor browser expressions with shared high-level JS helpers (increment 1)
status: completed
type: task
priority: normal
created_at: 2026-03-02T06:25:39Z
updated_at: 2026-03-02T06:36:13Z
---

## Problem
expressions.ex has repeated scoped query and field candidate JS scaffolding across many snippets.

## TODO
- [x] Extract shared scoped query helper block in expressions.ex
- [x] Refactor field action snippets to use shared helpers
- [x] Run format and targeted tests
- [x] Run precommit
- [x] Add summary of changes

## Summary of Changes
- Kept `select_set` at `/5` while continuing refactors around it to avoid conflicts with parallel edits.
- Extracted shared JS helper fragments in `expressions.ex`:
  - `scoped_query_setup/2` for scoped root/query/selector matching logic.
  - `form_field_candidates_snippet/0` and `file_field_candidates_snippet/0` for repeated field selection logic.
  - `scoped_roots_setup/1` and `labels_by_for_snippet/0` for additional high-level deduplication in snapshot/form/file flows.
- Applied the shared helpers across `clickables`, `form_fields`, `file_fields`, `upload_field`, `field_set`, `checkbox_set`, `radio_set`, and `button_click`.
- Verified behavior with targeted browser suites and full `mix precommit`.
