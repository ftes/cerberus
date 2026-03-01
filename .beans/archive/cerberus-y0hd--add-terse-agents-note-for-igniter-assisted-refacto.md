---
# cerberus-y0hd
title: Add terse AGENTS note for Igniter-assisted refactors
status: completed
type: task
priority: normal
created_at: 2026-02-28T14:34:41Z
updated_at: 2026-02-28T14:35:08Z
---

## Goal
Add a concise AGENTS.md guideline that Igniter should be used for refactors/renames when it helps.

## Todo
- [x] Add terse Igniter note in AGENTS.md
- [x] Run mix format and mix precommit
- [x] Summarize changes

## Summary of Changes
- Added a terse AGENTS guideline: "For refactors/renames, use Igniter when it helps."
- Ran `mix format` and `mix precommit` after the docs change; both passed.
