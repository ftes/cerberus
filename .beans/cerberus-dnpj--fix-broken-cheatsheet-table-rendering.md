---
# cerberus-dnpj
title: Fix broken cheatsheet table rendering
status: completed
type: bug
priority: normal
created_at: 2026-03-04T08:49:18Z
updated_at: 2026-03-04T08:50:30Z
---

Repair the markdown table in docs/cheatsheet.md where inline code containing pipes breaks row parsing.

- [x] Inspect broken table section and identify malformed rows/cells
- [x] Fix table formatting (remove pipeline examples from table cells)
- [x] Verify markdown renders correctly
- [x] Update bean summary and mark completed

## Summary of Changes
- Fixed the Browser-Only Extensions table in docs/cheatsheet.md by removing pipeline expressions from table cells.
- Replaced pipeline-form examples with equivalent function-call form for dialog assert, same-tab fallback, and assert_download rows.
- This avoids table-cell splitting in markdown renderers that mis-handle pipe characters in inline code spans.
