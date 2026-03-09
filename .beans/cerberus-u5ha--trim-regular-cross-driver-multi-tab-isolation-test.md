---
# cerberus-u5ha
title: Trim regular cross-driver multi-tab isolation test
status: completed
type: task
priority: normal
created_at: 2026-03-09T15:12:16Z
updated_at: 2026-03-09T15:17:46Z
---

## Goal

Reduce runtime of the regular-lane cross-driver multi-tab isolation test without weakening its parity contract.

## Tasks

- [ ] Profile the current browser and phoenix row costs
- [x] Remove redundant tab/session work while preserving isolation coverage
- [ ] Re-run targeted test plus regular and slow lanes
- [x] Summarize remaining slowest regular rows and bucket rationale

## Summary of Changes

Profiled the browser row and found the dominant cost was two fresh browser sessions plus extra tab navigation, not assertion work. Removed an unnecessary live counter detour and a redundant primary-session reassertion while preserving the actual contract: shared user state across tabs, isolation across independent sessions, and tab switching back to the original tab.

Result:

- browser row dropped from about 2346ms to about 1964ms
- phoenix row stayed cheap
