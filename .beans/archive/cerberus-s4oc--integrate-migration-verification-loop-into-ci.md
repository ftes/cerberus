---
# cerberus-s4oc
title: Integrate migration verification loop into CI
status: completed
type: task
priority: normal
created_at: 2026-02-28T08:47:02Z
updated_at: 2026-02-28T14:00:35Z
parent: cerberus-it5x
---

Wire migration verification automation into CI with practical runtime constraints for browser and non-browser lanes.

## Summary of Changes
- Updated CI smoke lane to run migration verification tests (test/cerberus/migration_verification_test.exs).
- Removed unnecessary browser runtime preparation from smoke and precommit jobs.
- Kept browser runtime setup only in browser_matrix job where browser conformance actually runs.
