---
# cerberus-fwox
title: Global screenshot defaults and artifact policy
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:11:06Z
updated_at: 2026-02-28T08:19:41Z
---

Define global screenshot defaults (path policy/full-page default/artifact location) with per-call override support.

## Summary of Changes

- Added browser-level screenshot defaults in `Cerberus.Driver.Browser`:
  - `screenshot_full_page` (default full-page capture behavior)
  - `screenshot_artifact_dir` (generated screenshot artifact directory)
  - `screenshot_path` (optional fixed default output path)
- Preserved per-call override precedence for `screenshot/2` options: call `path:`/`full_page:` values still win.
- Updated screenshot option validation so omitted `full_page` can inherit global config defaults.
- Added config-default coverage in `test/cerberus/timeout_defaults_test.exs` for screenshot full-page and screenshot path policy behavior.
- Updated README and cheat sheet docs with the new screenshot default knobs.
