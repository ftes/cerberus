---
# cerberus-xald
title: Document popup/new-window-to-same-tab workaround pattern
status: completed
type: task
priority: normal
created_at: 2026-02-28T15:12:09Z
updated_at: 2026-03-02T08:45:10Z
---

Workaround scope: users can often force popup flows into current tab by intercepting window.open or removing target=_blank.

## Scope
- Document canonical workaround snippets
- Add examples for OAuth-ish redirect/result flows
- Clarify when workaround is acceptable vs brittle

Research note: check Capybara/Cuprite behavior first; if unclear, fallback to Playwright JS/docs for confirmation.

## TODO
- [x] Document popup/new-window same-tab workaround patterns with concrete snippets
- [x] Clarify when workaround is acceptable vs brittle and when Browser.with_popup/4 is preferred
- [x] Run precommit and add summary of changes

## Summary of Changes
- Updated README popup guidance to make Browser.with_popup/4 the preferred deterministic approach and keep popup_mode: :same_tab as fallback.
- Added concrete same-tab workaround snippet for OAuth-style redirect/result flow using popup_mode: :same_tab.
- Added explicit brittle-vs-acceptable guidance and preference criteria for when to use with_popup/4 instead of same-tab rewriting.
- Updated browser support policy with a dedicated same-tab workaround section and decision guidance.
- Added a cheatsheet row for popup same-tab fallback usage.
