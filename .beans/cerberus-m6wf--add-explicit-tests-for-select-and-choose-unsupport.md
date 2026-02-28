---
# cerberus-m6wf
title: Add explicit tests for select and choose unsupported behavior
status: todo
type: task
created_at: 2026-02-28T15:08:23Z
updated_at: 2026-02-28T15:08:23Z
---

Missing-tests follow-up: select/choose are public APIs but explicit unsupported semantics are not directly tested.

## Scope
- Add tests asserting current unsupported behavior and error messaging
- Cover both phoenix and browser sessions where relevant

## Acceptance
- select/choose unsupported behavior is pinned by tests
