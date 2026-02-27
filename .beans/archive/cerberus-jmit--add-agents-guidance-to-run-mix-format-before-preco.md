---
# cerberus-jmit
title: Add AGENTS guidance to run mix format before precommit
status: completed
type: task
priority: normal
created_at: 2026-02-27T15:14:52Z
updated_at: 2026-02-27T15:15:02Z
---

Update AGENTS.md to explicitly instruct running mix format after logical change sets and before precommit because precommit uses format --check-formatted.

## Summary of Changes
- Updated AGENTS.md General Guidelines with an explicit formatting workflow line.
- Added guidance to run mix format after each logical change set and before tests/precommit.
- Clarified that mix precommit checks formatting and does not rewrite files.
