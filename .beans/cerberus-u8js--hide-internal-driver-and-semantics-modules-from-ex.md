---
# cerberus-u8js
title: Hide internal driver and semantics modules from ExDoc public surface
status: todo
type: task
created_at: 2026-02-28T15:08:13Z
updated_at: 2026-02-28T15:08:13Z
---

Finding follow-up: Cerberus currently documents internal modules as public API in ExDoc.

## Scope
- Mark non-public driver/semantics modules with @moduledoc false (or explicitly exclude from docs)
- Keep user-facing modules documented
- Verify docs output only contains intended public contract

## Acceptance
- Internal implementation modules are no longer presented as supported API docs
- README/guides remain accurate
