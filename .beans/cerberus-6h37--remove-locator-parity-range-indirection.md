---
# cerberus-6h37
title: Remove locator parity range indirection
status: completed
type: task
priority: normal
created_at: 2026-03-09T16:28:51Z
updated_at: 2026-03-09T16:34:09Z
---

## Goal

Remove run_case_range and all_parity_cases slicing indirection from locator_parity_test and make the parity groups explicit.

## Tasks

- [x] Replace range-based case slicing with explicit group-specific case definitions or helpers
- [x] Keep the same parity coverage and setup_all behavior
- [x] Re-run targeted locator parity tests and the unified full gate
- [x] Summarize the simplification

## Summary of Changes

Removed the remaining locator parity range indirection. locator_parity_test now uses explicit describe blocks plus explicit group case helpers assertion_cases, form_control_cases, composition_cases, and count_and_scope_cases. The file no longer uses parity_range, run_case_range, all_parity_cases, slice_cases, or find_case_index. Verified with a targeted locator parity rerun and the unified mix do format + precommit + test gate.
