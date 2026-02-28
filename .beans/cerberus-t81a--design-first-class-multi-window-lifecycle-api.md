---
# cerberus-t81a
title: Design first-class multi-window lifecycle API
status: todo
type: feature
created_at: 2026-02-28T15:12:09Z
updated_at: 2026-02-28T15:12:09Z
---

Gap scope: no first-class APIs for popup/new-window handles, switching, waiting, and close/return flows.

## Scope
- Propose API shape and lifecycle semantics
- Cover practical scenarios (OAuth popup, preview/export windows)
- Add conformance tests for deterministic window switching behavior

Research note: check Capybara/Cuprite behavior first; if unclear, fallback to Playwright JS/docs for confirmation.
