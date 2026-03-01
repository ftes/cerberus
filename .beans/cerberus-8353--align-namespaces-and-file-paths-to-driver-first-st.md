---
# cerberus-8353
title: Align namespaces and file paths to driver-first structure
status: todo
type: task
created_at: 2026-03-01T17:33:28Z
updated_at: 2026-03-01T17:33:28Z
parent: cerberus-whq9
---

Phase 1: Namespace/path alignment with minimal behavior risk.

Goals:
- Ensure module names match file paths and top-level driver-first organization.
- Keep concern-specific modules under driver namespaces unless truly shared.
- Preserve existing public API behavior during this phase.

## Todo
- [ ] Define and apply rename map for modules and files
- [ ] Update aliases/imports/references across lib and test
- [ ] Keep deprecation shims only if needed for internal transition
- [ ] Run format and precommit
