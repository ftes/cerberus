---
# cerberus-3v1y
title: Refactor browser expressions file field lookup helper (increment 10)
status: completed
type: task
priority: normal
created_at: 2026-03-02T07:19:57Z
updated_at: 2026-03-02T07:21:00Z
---

## Problem
expressions.ex still repeats file input candidate plus indexed lookup setup in upload flow.

## TODO
- [x] Extract shared indexed file-field lookup helper
- [x] Apply helper in upload_field flow
- [x] Run format and targeted tests
- [x] Run precommit
- [x] Add summary of changes

## Summary of Changes
- Added indexed_file_field_snippet helper to centralize file field candidate collection and indexed lookup.
- Applied helper in upload_field while preserving behavior.
- Ran format, targeted browser tests (49 tests), and precommit successfully.
