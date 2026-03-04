---
# cerberus-jy63
title: Set ExDoc source_ref to release git tag
status: completed
type: task
priority: normal
created_at: 2026-03-04T13:51:47Z
updated_at: 2026-03-04T13:52:45Z
---

## Goal\n\nConfigure ExDoc links to point at the corresponding release tag (for example v0.1.2) instead of main.\n\n## Todo\n\n- [x] Inspect ../ptp mix.exs docs config for source_ref pattern\n- [x] Apply same pattern in cerberus mix.exs docs config\n- [x] Regenerate docs and verify source links use version tag\n- [x] Summarize and close bean

## Summary of Changes

- Adopted the same ExDoc version-tag pattern used in ../ptp by introducing @version and using source_ref v interpolation.
- Updated project version/source constants to avoid duplication and keep docs source links tied to release tag.
- Regenerated docs and verified View Source links point to blob v0.1.2 for module and guide pages.
