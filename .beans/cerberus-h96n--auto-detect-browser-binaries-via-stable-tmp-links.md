---
# cerberus-h96n
title: Auto-detect browser binaries via stable tmp links
status: completed
type: task
priority: normal
created_at: 2026-03-03T15:38:58Z
updated_at: 2026-03-03T15:45:06Z
---

Goal: make local browser setup automatic after install tasks by using stable tmp symlink targets, so users do not need explicit browser binary config/env for standard runs.

## Tasks
- [x] Audit install task outputs and runtime binary resolution
- [x] Implement stable tmp symlink creation in install flow
- [x] Add runtime fallback lookup to symlink defaults
- [x] Update tests/docs and validate with focused test runs

## Summary of Changes
- Added stable-link creation to browser install flow in `Cerberus.Browser.Install`: installs now refresh `tmp/chrome-current`, `tmp/chromedriver-current`, `tmp/firefox-current`, and `tmp/geckodriver-current` symlinks to the installed binaries.
- Added runtime binary fallback resolution in `Cerberus.Driver.Browser.Runtime`: binary lookup order is session opts -> app config -> env vars (`CHROME`, `CHROMEDRIVER`, `FIREFOX`, `GECKODRIVER`) -> stable `tmp/*-current` links.
- Removed hard `System.fetch_env!` binary requirements from `config/test.exs` so non-browser test runs do not require browser env vars at config load.
- Updated install-task tests to validate stable symlink creation and added per-test stable-link dir isolation.
- Updated docs (`README.md`, `docs/getting-started.md`, `docs/browser-support-policy.md`) to describe automatic binary discovery after install tasks instead of mandatory binary-path config.
