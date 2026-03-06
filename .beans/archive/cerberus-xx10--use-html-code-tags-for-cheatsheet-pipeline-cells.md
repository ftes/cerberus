---
# cerberus-xx10
title: Use HTML code tags for cheatsheet pipeline cells
status: completed
type: task
priority: normal
created_at: 2026-03-04T09:04:27Z
updated_at: 2026-03-04T09:10:12Z
---

Update docs/cheatsheet.md browser extension table examples to use HTML code tags so pipeline expressions render safely in markdown tables.

- [x] Replace affected table examples with HTML code tags and escaped pipes
- [x] Run mix docs
- [x] Verify doc/cheatsheet.html rendering in Playwright
- [x] Update bean summary and mark completed

## Summary of Changes

Tried HTML <code> tags in cheatsheet table cells first; verified via Playwright that ExDoc escaped them as literal text.
Switched to markdown code spans with escaped table pipes (\|>) between spans for pipeline rows.
Regenerated docs with mix docs and verified doc/cheatsheet.html#browser-only-extensions in Playwright now renders correctly with visible |> operators and intact table rows.
