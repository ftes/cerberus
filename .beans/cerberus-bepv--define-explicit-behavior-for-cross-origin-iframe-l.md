---
# cerberus-bepv
title: Define explicit behavior for cross-origin iframe limitations
status: todo
type: task
created_at: 2026-02-28T15:12:09Z
updated_at: 2026-02-28T15:12:09Z
---

Limitation scope: cross-origin iframe DOM interaction cannot be driven directly through custom JS due to same-origin policy.

## Scope
- Decide product behavior (explicit error, docs-only limitation, or future API placeholder)
- Add user-facing docs with practical alternatives
- Add tests that pin expected failure behavior/messages

Research note: check Capybara/Cuprite behavior first; if unclear, fallback to Playwright JS/docs for confirmation.
