---
# cerberus-wg7d
title: Move assert_path/refute_path execution into drivers
status: todo
type: task
priority: normal
created_at: 2026-03-03T19:54:20Z
updated_at: 2026-03-03T19:54:28Z
parent: cerberus-5xxo
---

## Goal
Move assert_path/refute_path execution semantics into driver modules.

## Todo
- [ ] Add assert_path/refute_path callbacks to driver behavior
- [ ] Implement per-driver path assertion logic
- [ ] Keep timeout and error message semantics compatible
- [ ] Run format + targeted path assertion tests
