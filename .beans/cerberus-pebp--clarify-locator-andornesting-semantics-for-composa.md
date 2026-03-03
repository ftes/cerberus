---
# cerberus-pebp
title: Clarify locator and/or/nesting semantics for composable API
status: completed
type: task
priority: normal
created_at: 2026-03-03T09:21:08Z
updated_at: 2026-03-03T09:22:14Z
---

Define precise semantics for composable locator APIs after deciding to allow OR in actions with strict uniqueness at execution.\n\nScope:\n- [x] Confirm action behavior for OR (strict uniqueness enforced by operation)\n- [x] Explain API shape for AND vs OR vs nested composition with concrete examples\n- [x] Clarify difference between explicit AND composition and nesting semantics

## Summary of Changes\nAligned semantics for composable locators:\n- OR is allowed for actions; action operations enforce strict uniqueness at execution time.\n- AND means same-element intersection of predicates.\n- Nesting means relational composition (ancestor/descendant), not same-element intersection.\nPrepared concrete API examples using pipe composition to illustrate AND, OR, and nested cases, including where AND and nesting differ on the same DOM.
