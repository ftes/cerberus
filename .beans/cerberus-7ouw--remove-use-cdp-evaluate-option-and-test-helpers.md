---
# cerberus-7ouw
title: Remove use_cdp_evaluate option and test helpers
status: completed
type: task
priority: normal
created_at: 2026-03-12T09:48:35Z
updated_at: 2026-03-12T09:55:13Z
---

Remove the remaining use_cdp_evaluate option, helper plumbing, and tests from Cerberus with a clean cut, then fix any failing tests caused by the removal.

- [x] inspect remaining use_cdp_evaluate references and dirty worktree overlap
- [x] remove public option and internal dead branches
- [x] remove or update tests/helpers that depend on use_cdp_evaluate
- [x] run targeted and full test gates
- [x] summarize and complete bean

## Summary of Changes

Removed `use_cdp_evaluate` from the public browser session option schemas and deleted the dead CDP evaluate browser-process path, including the unused `CdpPageProcess`. Updated shared browser test helpers, direct browser tests, timeout coverage, and docs to stop referencing the option. Also fixed invalid `select/4` call sites already present in the locator parity test so the suite would pass after the clean cut. Verified with targeted browser suites and the full `MIX_ENV=test mix do format + precommit + test` gate.
