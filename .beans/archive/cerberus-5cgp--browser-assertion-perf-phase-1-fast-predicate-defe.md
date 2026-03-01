---
# cerberus-5cgp
title: 'Browser assertion perf phase 1: fast predicate + deferred diagnostics'
status: completed
type: task
priority: normal
created_at: 2026-03-01T15:52:40Z
updated_at: 2026-03-01T15:54:51Z
---

Optimize browser text assertion waits by splitting fast match checks from heavy debug snapshot generation.

## Todo
- [x] Refactor in-browser text wait to run boolean fast checks during polling
- [x] Generate full texts/matched payload only on final success/failure snapshot
- [x] Keep semantics identical for exact regex normalize_ws visible selector

## Summary of Changes
- Refactored browser in-page text assertion waiting to use cheap boolean checks during wait iterations instead of rebuilding full diagnostics on every poll.
- Deferred full texts and matched array construction to final snapshot emission, preserving assertion error payload shape and matcher semantics.
- Kept exact, regex, normalize_ws, visible, and selector behavior intact while reducing repeated per-check work in the hot loop.
