---
# cerberus-pwma
title: Document and_ versus pipe equivalence in locator cheatsheet
status: completed
type: task
priority: normal
created_at: 2026-03-04T19:49:21Z
updated_at: 2026-03-04T19:50:15Z
---

## Goal
Update locator cheatsheet to state that helper pipe composition and and_ are equivalent for intersection semantics, and explain why both APIs exist.

## Tasks
- [x] Locate locator cheatsheet source section for composition
- [x] Add concise equivalence note and rationale
- [x] Build docs quickly to ensure markdown renders

## Summary of Changes
- Updated `docs/cheatsheet.md` composition section to explicitly show the equivalent `and_` form for piped same-element intersection.
- Added rationale text: pipe style for inline readability; `and_` for combining pre-built locators and symmetry with `or_`/`not_`.
- Ran `mix docs` successfully and verified docs generation completed.
