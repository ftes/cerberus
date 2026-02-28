---
# cerberus-e1ym
title: Clarify and constrain unwrap browser escape hatch usage
status: todo
type: task
created_at: 2026-02-28T15:12:09Z
updated_at: 2026-02-28T15:12:09Z
---

Boundary scope: unwrap can expose unstable browser internals not intended as public contract.

## Scope
- Document current instability/constraints clearly
- Define guardrails for usage in tests
- Decide whether to harden, hide, or replace this escape hatch for browser internals

Research note: check Capybara/Cuprite behavior first; if unclear, fallback to Playwright JS/docs for confirmation.
