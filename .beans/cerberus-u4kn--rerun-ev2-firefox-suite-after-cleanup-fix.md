---
# cerberus-u4kn
title: Rerun EV2 Firefox suite after cleanup fix
status: completed
type: task
priority: normal
created_at: 2026-03-12T17:09:55Z
updated_at: 2026-03-12T17:15:25Z
---

Re-run the EV2 Cerberus Firefox suite after the Firefox cleanup fix, capture the remaining failures, and verify whether new runs leave orphaned Firefox processes behind.

- [x] run the full EV2 Cerberus Firefox suite after the cleanup fix
- [x] summarize the remaining failures
- [x] verify whether Firefox processes are clean after the rerun

## Summary of Changes

- Re-ran the full EV2 Cerberus Firefox suite after the Firefox cleanup fix with `mix test --only cerberus --max-cases 14`.
- Result: 689 tests, 0 failures, 30 skipped, 5042 excluded, finished in 289.5s.
- Checked for Firefox processes after the run and found none beyond the `pgrep` shell itself, so the cleanup fix held under a full suite run.
