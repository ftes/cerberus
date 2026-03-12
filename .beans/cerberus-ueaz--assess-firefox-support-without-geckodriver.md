---
# cerberus-ueaz
title: Assess Firefox support without geckodriver
status: completed
type: task
priority: normal
created_at: 2026-03-12T05:59:19Z
updated_at: 2026-03-12T06:01:42Z
---

## Todo

- [x] Review current browser runtime and configuration paths
- [x] Review install/docs/test expectations for Firefox
- [x] Summarize implementation effort and main blockers

## Summary of Changes

- Reviewed the active Chrome-only runtime, option schema, bootstrap, and docs surfaces to identify where Firefox support was intentionally removed.
- Verified the repo still carries a Firefox-capable BiDi transport dependency (`Bibbidi.Browser`) and recent history showing Firefox support existed on March 8-9, 2026 before the Chrome-only simplification.
- Estimated Firefox reintroduction effort as a restoration/modularization task rather than a greenfield browser implementation, with the main work in runtime selection, option/bootstrap/docs re-expansion, and parity verification.
