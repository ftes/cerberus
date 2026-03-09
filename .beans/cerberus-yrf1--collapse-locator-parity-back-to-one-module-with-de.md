---
# cerberus-yrf1
title: Collapse locator parity back to one module with describe blocks
status: completed
type: task
priority: normal
created_at: 2026-03-09T16:07:41Z
updated_at: 2026-03-09T16:27:57Z
---

## Goal

Keep locator_parity_test in one async module with distinct describe blocks instead of multiple test modules.

## Tasks

- [x] Replace the split locator parity modules with one module and grouped describe blocks
- [x] Keep the same parity coverage and setup_all behavior
- [x] Re-run targeted locator parity tests and the unified full gate
- [x] Summarize whether any other test files still use multiple test modules

## Summary of Changes

Merged locator_parity_test back into one async test module, replaced the generated group loop with explicit describe blocks, and removed the parity_groups and parity_cases indirection. The file now keeps one all_parity_cases source plus explicit range constants and a run_case_range helper. Verified with a targeted locator parity rerun and the unified mix do format + precommit + test gate. The only remaining multi-module files under test are fixture .ex files, not multi-module test files.
