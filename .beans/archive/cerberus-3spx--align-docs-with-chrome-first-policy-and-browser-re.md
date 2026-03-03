---
# cerberus-3spx
title: Align docs with chrome-first policy and browser retry model
status: completed
type: task
priority: normal
created_at: 2026-03-03T14:22:04Z
updated_at: 2026-03-03T14:24:56Z
---

Audit README, docs guides, and public moduledocs for drift versus current implementation.\n\nScope:\n- [ ] Verify browser support policy wording matches CI reality (chrome-only lane today).\n- [ ] Update README and docs guides where they claim firefox CI coverage or first-class parity.\n- [ ] Document current browser assertion/path execution model: in-browser wait loops plus bounded transient BiDi eval retry.\n- [ ] Update public moduledoc statements that still describe one-shot slice behavior as current state.\n- [ ] Run format and precommit.\n- [x] Add summary of changes.

## Summary of Changes

Audited README, docs guides, browser support policy, and public Cerberus moduledoc against current browser-driver behavior and CI policy.

Updated docs to reflect current Chrome-first execution policy for regular local and CI runs while keeping Firefox as opt-in/explicit.

Added browser assertion/path execution model notes: in-browser wait loops are the fast path, with bounded transient BiDi eval retries for navigation/context-reset races.

Removed stale one-shot wording in public Cerberus moduledoc and within docs wording.

Validation:
- mix format
- mix precommit
