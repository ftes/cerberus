---
# cerberus-jo8a
title: Remove Session.driver_kind and Any impl
status: in-progress
type: task
priority: normal
created_at: 2026-03-03T19:45:27Z
updated_at: 2026-03-03T19:45:35Z
---

## Goal
Remove Session.driver_kind API and Any fallback implementation, and tighten LastResult op type to Session.operation().

## Todo
- [ ] Remove driver_kind callback/type and impls from Session protocol
- [ ] Replace Session.driver_kind call sites with local struct-based helper
- [ ] Remove defimpl Session for Any
- [ ] Tighten LastResult op types/specs to Session.operation()
- [ ] Run mix format and targeted tests
