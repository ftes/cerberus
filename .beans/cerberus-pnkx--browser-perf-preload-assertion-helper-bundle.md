---
# cerberus-pnkx
title: 'Browser perf: preload assertion helper bundle'
status: completed
type: task
priority: normal
created_at: 2026-03-01T16:05:52Z
updated_at: 2026-03-01T16:10:14Z
blocked_by:
    - cerberus-f0l5
---

Inject reusable assertion JS helpers once per browser user context and call compact wrappers.

## Todo
- [x] Register Cerberus helper preload script in browser context startup
- [x] Migrate text and path assertions to helper wrapper calls
- [x] Validate browser assertion suites with direnv-loaded env

## Summary of Changes
- Added a dedicated browser assertion helper preload bundle module and injected it as an internal init script for each browser user context.
- Migrated browser text and path assertion expression builders to compact wrapper calls into the preloaded helper API, with safe missing-helper diagnostics.
- Verified browser and live targeted suites under direnv-loaded runtime environment.
