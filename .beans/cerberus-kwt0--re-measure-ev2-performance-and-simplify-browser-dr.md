---
# cerberus-kwt0
title: Re-measure EV2 performance and simplify browser driver if needed
status: in-progress
type: task
created_at: 2026-03-08T09:03:34Z
updated_at: 2026-03-08T09:03:34Z
---

## Scope

- [ ] Re-run the restored EV2 original vs Cerberus timing comparisons after the latest browser-driver changes.
- [ ] Summarize the updated Playwright/PhoenixTest vs Cerberus gap.
- [ ] Inspect the browser driver for leftover complexity/stale readiness plumbing after the semantic changes.
- [ ] If cleanup is justified, implement a targeted simplification/refactor and verify it.
- [ ] Commit only the relevant Cerberus changes and bean files.
