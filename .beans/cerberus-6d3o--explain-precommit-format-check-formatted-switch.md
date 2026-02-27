---
# cerberus-6d3o
title: Explain precommit format --check-formatted switch
status: completed
type: task
priority: normal
created_at: 2026-02-27T15:11:38Z
updated_at: 2026-02-27T15:12:30Z
---

Investigate when and why precommit switched to mix format --check-formatted instead of auto-formatting; report rationale and commit context.

## Summary of Changes
- Checked mix.exs git history for precommit alias changes.
- Verified format --check-formatted was present from initial mix.exs commit (cc7d807, 2026-02-27) and remained in later committed updates (34c2627, 2026-02-27).
- Confirmed from bean cerberus-i3i4 notes that precommit intentionally runs checks (format --check-formatted, credo --strict, tests) instead of mutating files.
- Observed current local uncommitted edits add Dialyzer but still keep format --check-formatted.
