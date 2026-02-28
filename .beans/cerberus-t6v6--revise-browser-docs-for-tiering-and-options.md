---
# cerberus-t6v6
title: Revise browser docs for tiering and options
status: completed
type: task
priority: normal
created_at: 2026-02-28T15:02:00Z
updated_at: 2026-02-28T15:06:36Z
---

## Goal\n\nUpdate docs to reflect Chrome+Firefox as top-tier support, simplify/remove tier-detail prose, remove ALLCAPS env-var style mentions, and document show_browser plus other browser options clearly.\n\n## Checklist\n\n- [x] Audit current docs and runtime option support\n- [x] Update docs (README + guides/policy) for support status and options\n- [x] Run mix format and verify doc changes

## Summary of Changes

- Updated README browser docs to state Chrome and Firefox as fully supported targets.
- Removed tier taxonomy/detail from browser policy and replaced with concise current support + runtime model.
- Removed ALLCAPS env-var style docs references and replaced with explicit config keys.
- Documented show_browser with runtime-level scope and headless precedence.
- Added explicit docs coverage for related runtime options and where they apply (session context vs global runtime/defaults).
