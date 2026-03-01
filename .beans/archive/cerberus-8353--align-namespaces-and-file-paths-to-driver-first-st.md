---
# cerberus-8353
title: Align namespaces and file paths to driver-first structure
status: completed
type: task
priority: normal
created_at: 2026-03-01T17:33:28Z
updated_at: 2026-03-01T19:02:55Z
parent: cerberus-whq9
---

Phase 1: Namespace/path alignment with minimal behavior risk.

Goals:
- Ensure module names match file paths and top-level driver-first organization.
- Keep concern-specific modules under driver namespaces unless truly shared.
- Preserve existing public API behavior during this phase.

## Todo
- [x] Define and apply rename map for modules and files
- [x] Update aliases/imports/references across lib and test
- [x] Keep deprecation shims only if needed for internal transition (no shims required)
- [x] Run format and precommit

## Summary of Changes
- Renamed Phoenix concern modules to `Cerberus.Phoenix.*` (`Conn`, `LiveViewBindings`, `LiveViewHTML`, `LiveViewTimeout`, `LiveViewWatcher`).
- Updated all aliases/imports/usages across library code to the new namespaces.
- Moved Phoenix-focused tests into `test/cerberus/phoenix` and renamed test modules to match canonical module names.
- Updated architecture documentation to reference `Cerberus.Phoenix.LiveViewHTML`.
- Verified with `mix test test/cerberus` and `mix precommit`.
