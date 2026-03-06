---
# cerberus-ve21
title: Fix install task script path resolution in downstream projects
status: completed
type: bug
priority: normal
created_at: 2026-03-04T17:33:53Z
updated_at: 2026-03-04T17:44:15Z
---

## Goal

Ensure mix cerberus.install.chrome works when Cerberus is used as a dependency from another project, resolving installer script path from the Cerberus app itself.

## Todo

- [x] Reproduce/inspect failure context in ../ev2
- [x] Locate install task script path resolution logic
- [x] Update resolution to use Cerberus app path
- [x] Validate task in downstream project context
- [x] Summarize and close bean

## Summary of Changes

- Fixed installer script discovery in `Cerberus.Browser.Install` to stop resolving via caller cwd `bin` paths.
- Simplified path resolution using prior-art from EctoSQL-style handling: `Mix.Project.deps_paths()[:cerberus]` in downstream apps.
- Added a robust local fallback via `Path.dirname(Mix.Project.project_file())` so changing cwd during tests does not break lookup.
- Kept installer behavior strict: fail fast with a clear missing-script path message.
- Added regression coverage proving the task does not resolve `bin/chrome.sh` from the caller cwd.
- Verified via focused test run: `source .envrc && PORT=4207 mix test test/mix/tasks/cerberus_install_tasks_test.exs:64`.
