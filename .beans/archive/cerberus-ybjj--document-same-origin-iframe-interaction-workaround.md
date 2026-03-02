---
# cerberus-ybjj
title: Document same-origin iframe interaction workaround via custom JS
status: scrapped
type: task
priority: normal
created_at: 2026-02-28T15:12:09Z
updated_at: 2026-03-02T11:39:01Z
---

Workaround scope: users can often interact with same-origin iframes via Browser.evaluate_js and dispatched events.

## Scope
- Document supported workaround pattern and limitations
- Add tested examples for common actions (read/write/click/dispatch)
- Clarify failure modes and diagnostics

Research note: check Capybara/Cuprite behavior first; if unclear, fallback to Playwright JS/docs for confirmation.

## Reasons for Scrapping
- Same-origin iframe interaction is now supported directly via locator-based `within/3` root switching in browser mode, so a separate workaround-focused doc task is no longer needed.
- The desired guidance is covered by current README/getting-started documentation updates and browser iframe tests.
