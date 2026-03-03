---
# cerberus-ah1q
title: Restore profiling bucket driver kind labels
status: completed
type: bug
priority: normal
created_at: 2026-03-03T20:46:18Z
updated_at: 2026-03-03T20:47:49Z
---

## Goal
Restore profiling bucket labels to stable driver kind atoms (:static/:live/:browser) after facade slimming changed some buckets to module names.

## Todo
- [x] Update Cerberus profiling bucket key construction for visit and path assertions
- [x] Run format and focused profiling regression tests
- [x] Run precommit and commit code + bean

## Summary of Changes
- Restored profiling bucket labels to stable driver kind atoms for Cerberus.visit and path assertion orchestration (:static/:live/:browser).
- Verified regression with focused suite: test/cerberus/profiling_test.exs passes.
- mix precommit is currently blocked by unrelated formatting drift in lib/cerberus/driver/browser/extensions.ex that predates this fix; committing only the profiling-fix slice as requested.
