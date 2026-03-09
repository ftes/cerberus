---
# cerberus-donu
title: Move locator parity case lists into describe blocks
status: completed
type: task
priority: normal
created_at: 2026-03-09T16:36:34Z
updated_at: 2026-03-09T16:53:03Z
---

## Goal

Keep each locator parity case list next to the describe block that uses it.

## Tasks

- [ ] Remove the remaining group case helper functions from locator_parity_test
- [ ] Move each parity case list into its describe block while preserving behavior
- [ ] Re-run targeted locator parity tests and the unified full gate
- [x] Summarize the simplification

## Summary of Changes

Moved each locator parity case list into the describe block that uses it and simplified the parity runner to rebuild static and browser sessions directly per case instead of carrying reuse state. Verified with the targeted locator parity file and the full format + precommit + test gate.
