---
# cerberus-3b1u
title: Internalize or remove public helper seams session_for_driver and driver_module
status: todo
type: task
created_at: 2026-02-28T15:08:13Z
updated_at: 2026-02-28T15:08:13Z
---

Finding follow-up: hidden helper functions in Cerberus are still publicly callable and used by harness internals.

## Scope
- Remove/relocate public helper API seams not intended for end users
- Update harness internals to avoid reliance on public helper exposure
- Preserve test behavior and failure messages

## Acceptance
- Helpers are no longer accidental public API
