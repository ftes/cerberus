---
# cerberus-p15y
title: Set EV2 Cerberus live timeout to 2000ms
status: in-progress
type: task
priority: normal
created_at: 2026-03-07T07:29:13Z
updated_at: 2026-03-07T07:29:26Z
---

## Scope

- [x] Add an EV2-only Cerberus live timeout override of 2000ms in config/test.exs.
- [ ] Re-run the full migrated EV2 Cerberus suite with random PORT and MIX_ENV=test.
- [ ] Summarize whether the remaining failures were reduced and note any non-timeout blockers.
