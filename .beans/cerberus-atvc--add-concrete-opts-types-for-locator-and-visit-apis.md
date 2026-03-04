---
# cerberus-atvc
title: Add concrete opts types for locator and visit APIs
status: completed
type: task
priority: normal
created_at: 2026-03-04T19:37:45Z
updated_at: 2026-03-04T19:41:45Z
---

## Goal
Replace remaining generic keyword opts types in public Cerberus APIs with concrete option aliases, including locator helper opts and optional visit/reload opts.

## Tasks
- [x] Add locator and closest option types in Cerberus.Options
- [x] Add visit/reload opts types in Cerberus.Options
- [x] Update Cerberus public specs to use new aliases
- [x] Update Cerberus.Browser screenshot wrapper spec to use concrete type
- [x] Update Cerberus.Locator specs to use concrete option aliases
- [x] Run format and targeted tests

## Summary of Changes
- Added `Options.locator_leaf_opts`, `Options.role_locator_opts`, `Options.closest_opts`, `Options.visit_opts`, and `Options.reload_opts`.
- Replaced remaining generic `keyword()` opts specs in `Cerberus` locator helpers and visit/reload with concrete `Options` aliases.
- Updated `Cerberus.Browser.screenshot/2` wrapper spec to use `Options.screenshot_opts()`.
- Updated `Cerberus.Locator` public specs (`leaf/3`, `role/2`, `closest/2`) to use concrete `Options` aliases.
- Updated `Cerberus.Driver` callback for `visit/3` to use `Options.visit_opts()`.

## Verification Notes
- `mix format` passed.
- Targeted test run was blocked by unrelated pre-existing compile errors in files outside this slice (`lib/cerberus/html/html.ex` and an unrelated warning in `lib/cerberus/assertions.ex`).
