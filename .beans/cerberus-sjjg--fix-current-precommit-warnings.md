---
# cerberus-sjjg
title: Fix current precommit warnings
status: completed
type: bug
priority: normal
created_at: 2026-03-04T19:54:32Z
updated_at: 2026-03-04T20:12:14Z
---

## Goal
Resolve current precommit warnings/failures in this workspace.

## Tasks
- [x] Run precommit and capture current failures
- [x] Fix reported warnings in affected files
- [x] Run format and precommit again to verify clean

## Summary of Changes
- Refactored nested conditionals flagged by Credo in Cerberus.Html, migration task canonicalization, and auth store fixture helpers.
- Removed Dialyzer-unreachable branches in static/live/browser locator assertion helper logic and open browser static path rewriting.
- Fixed slow test expectations for locator parity and migration fixture rewrite output to match current behavior.
- Verified clean with mix precommit, mix test, and mix test --only slow using sourced env and random PORT values.
