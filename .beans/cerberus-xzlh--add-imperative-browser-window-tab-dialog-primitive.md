---
# cerberus-xzlh
title: Add imperative browser window tab dialog primitives with sugar wrappers
status: todo
type: feature
created_at: 2026-03-09T18:58:52Z
updated_at: 2026-03-09T18:58:52Z
---

## Goal

Introduce a lower-level imperative browser control layer for windows, tabs, and dialogs, then layer ergonomic callback/pipeline helpers on top.

## Scope

- Add explicit low-level APIs for opening/switching/awaiting tabs and windows.
- Add explicit low-level APIs for expecting/awaiting/accepting/dismissing dialogs.
- Keep session-first browser handles as the public top-level abstraction.
- Rebuild sugar helpers like popup/dialog callback wrappers on top of the imperative primitives.

## Notes

This follows the clean-cut removal of the old dialog assertion/auto-handling slice. The new foundation should make ordering and race boundaries explicit, with callback-style helpers as wrappers rather than the primitive contract.
