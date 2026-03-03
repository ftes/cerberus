---
# cerberus-jo8a
title: Remove Session.driver_kind and Any impl
status: completed
type: task
priority: normal
created_at: 2026-03-03T19:45:27Z
updated_at: 2026-03-03T22:21:50Z
---

## Goal
Remove Session.driver_kind API and Any fallback implementation, and tighten LastResult op type to Session.operation().

## Scope
- [x] Remove driver_kind callback and type from Session protocol.
- [x] Replace Session.driver_kind usage with local struct-based helpers in call sites.
- [x] Remove defimpl Session for Any.
- [x] Tighten LastResult op types and specs to Session.operation().
- [x] Run formatting and validation in normal precommit flow.

## Summary of Changes
- Session protocol now only exposes current_path, scope, with_scope, and last_result.
- Session implementations are now explicit for static, live, and browser only.
- Driver-kind profiling and error reporting use local helpers instead of protocol dispatch.
- LastResult now uses Session.operation() in struct type and constructor specs.
