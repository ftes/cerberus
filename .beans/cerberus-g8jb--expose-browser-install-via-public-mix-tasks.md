---
# cerberus-g8jb
title: Expose browser install via public Mix tasks
status: completed
type: feature
priority: normal
created_at: 2026-03-02T14:31:58Z
updated_at: 2026-03-02T15:00:22Z
---

Goal:
Expose browser runtime installation to Cerberus consumers via supported Mix tasks instead of bin scripts.

Scope:
- [x] Add public Mix tasks for installing Chrome+ChromeDriver and Firefox+GeckoDriver
- [x] Reuse existing install logic or extract shared installer modules to avoid script and task drift
- [x] Define stable output contract so consumers can discover installed binary paths and versions
- [x] Wire resolved versions and binary paths into Cerberus runtime config in a documented way
- [x] Evaluate best default integration path for test config bootstrapping (for example config/test.exs helper or runtime auto-discovery)
- [x] Document consumer workflow in README and getting started docs
- [x] Add tests for task behavior and configuration handoff

Open design questions:
- Should mix tasks write/update local env files, or should Cerberus auto-discover installed artifacts at runtime?
- How should browser version selection precedence work across task flags, env vars, and config?

## Decisions
- Mix tasks do not mutate local env files automatically.
- Runtime install tasks expose output contracts for shell and CI handoff.
- Version precedence is task flags, then env vars, then default versions from installer logic.

## Summary of Changes
- Added shared installer module Cerberus.Browser.Install that runs existing installer scripts, parses runtime metadata, and renders plain, json, env, and shell outputs.
- Added public tasks mix cerberus.install.chrome and mix cerberus.install.firefox with version flags and format controls.
- Added tests for task output contracts, option forwarding, format validation, and runtime config handoff mapping.
- Updated README and guides with canonical installer task workflow and runtime config wiring examples.
- Updated CI workflow to use mix installer tasks instead of calling bin scripts directly.
- Included bin scripts in package files so install tasks work for dependency consumers.
