---
# cerberus-3joo
title: Assess whether Session.transition is required
status: completed
type: task
priority: normal
created_at: 2026-03-03T19:11:20Z
updated_at: 2026-03-03T19:11:49Z
---

## Goal
Determine whether Session.transition is behavior-critical or only diagnostic.

## Todo
- [x] Audit Session.transition call sites in runtime code
- [x] Classify behavioral dependency vs diagnostics only
- [x] Summarize recommendation

## Summary of Changes
- Audited all runtime Session.transition/1 call sites.
- Found no control-flow decisions that depend on Session.transition values.
- Session.transition is used to populate observed payload metadata and assertion error diagnostics when a fresh transition is not provided.
- Recommendation: it is optional for core semantics; safe to remove if we accept leaner diagnostics (or replace with dedicated last_transition metadata).
