---
# cerberus-wg7d
title: Move assert_path/refute_path execution into drivers
status: completed
type: task
priority: normal
created_at: 2026-03-03T19:54:20Z
updated_at: 2026-03-03T20:07:25Z
parent: cerberus-5xxo
---

## Goal
Move assert_path/refute_path execution semantics into driver modules.

## Todo
- [x] Add assert_path/refute_path callbacks to driver behavior
- [x] Implement per-driver path assertion logic
- [x] Keep timeout and error message semantics compatible
- [x] Run format + targeted path assertion tests

## Summary of Changes
- Added assert_path and refute_path callbacks to Cerberus.Driver.
- Implemented path assertion execution in Static and Live drivers.
- Reused Browser driver path callbacks as behaviour implementations.
- Simplified Cerberus.assert_path and Cerberus.refute_path to delegate execution to drivers while preserving timeout retry behavior for non-browser sessions.
- Validation executed with targeted path and timeout suites.
