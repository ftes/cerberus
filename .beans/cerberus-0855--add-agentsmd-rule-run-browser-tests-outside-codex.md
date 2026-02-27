---
# cerberus-0855
title: 'Add AGENTS.md rule: run browser tests outside Codex sandbox'
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:07:12Z
updated_at: 2026-02-27T11:07:30Z
parent: cerberus-efry
---

## Scope
Document that browser-tagged test runs should be executed outside the Codex sandbox (escalated permissions) because Chrome startup is sandbox-sensitive.

## Done When
- [x] AGENTS.md includes explicit guidance for browser tests.
- [x] Bean contains summary and is marked completed.

## Summary of Changes

- Updated `AGENTS.md` Browser runtime policy with an explicit rule to run browser-tagged tests outside the Codex sandbox (escalated permissions).
- Captures the practical constraint observed in this project: Chrome startup can fail inside sandboxed execution even when binaries/config are correct.
