---
# cerberus-51ji
title: Reduce Cerberus to cross-driver facade only
status: completed
type: task
priority: normal
created_at: 2026-03-03T19:54:20Z
updated_at: 2026-03-03T20:17:33Z
parent: cerberus-5xxo
---

## Goal
Trim Cerberus module to cross-driver façade responsibilities only.

## Todo
- [x] Audit remaining driver-specific branches/helpers in Cerberus
- [x] Move candidate helper logic to drivers or shared modules
- [x] Remove now-dead top-level helpers
- [x] Run format + targeted regression suites

## Summary of Changes
- Added a within callback to the Cerberus.Driver behaviour and implemented it in static, live, and browser drivers.
- Reduced Cerberus.within/3 to a thin normalize-and-dispatch facade.
- Moved driver-specific within scope resolution, live child-view optimization, and callback scope restoration into driver modules.
- Removed now-dead within helper functions from Cerberus.
- Validation: mix format, focused within/path/browser scope suites, and mix precommit.
