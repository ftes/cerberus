---
# cerberus-i672
title: Clarify label sigil removal and action label input
status: completed
type: task
priority: normal
created_at: 2026-03-06T10:27:47Z
updated_at: 2026-03-06T10:29:31Z
---

## Goal\nAnswer whether label sigil still exists and how label text should be passed to fill_in and other action ops.\n\n## Todo\n- [x] Check current API/docs for label sigil status\n- [x] Check fill_in and action-op argument conventions\n- [x] Reply with concrete guidance

## Summary of Changes
- Verified current locator sigil parser supports modifiers r/c/a/t/e/i and does not include a label-specific modifier.
- Verified action operation docs and tests use label(...) as the canonical way to pass label text to fill_in/check/uncheck/choose/select/upload.
- Prepared concise migration guidance for the user question.
