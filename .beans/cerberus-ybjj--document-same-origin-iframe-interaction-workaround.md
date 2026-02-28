---
# cerberus-ybjj
title: Document same-origin iframe interaction workaround via custom JS
status: todo
type: task
created_at: 2026-02-28T15:12:09Z
updated_at: 2026-02-28T15:12:09Z
---

Workaround scope: users can often interact with same-origin iframes via Browser.evaluate_js and dispatched events.

## Scope
- Document supported workaround pattern and limitations
- Add tested examples for common actions (read/write/click/dispatch)
- Clarify failure modes and diagnostics

Research note: check Capybara/Cuprite behavior first; if unclear, fallback to Playwright JS/docs for confirmation.
