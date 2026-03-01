---
# cerberus-04p8
title: Clarify second browser spawn policy
status: completed
type: task
priority: normal
created_at: 2026-02-28T14:59:40Z
updated_at: 2026-02-28T15:00:49Z
---

## Goal\n\nAnswer whether users can spawn a second browser process and whether Cerberus should ever do that.\n\n## Checklist\n\n- [x] Inspect runtime/browser supervision code and docs\n- [x] Provide clear guidance to user

## Summary of Changes

- Verified browser runtime topology and public API behavior.
- Confirmed Cerberus uses one shared runtime+BiDi per test invocation, with per-session userContext isolation and per-tab browsingContext isolation.
- Confirmed mixed browser lanes require separate test invocations rather than a second runtime in-process.
