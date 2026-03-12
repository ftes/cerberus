---
# cerberus-zq8l
title: Fix CI setup-beam workflow regression
status: completed
type: bug
priority: normal
created_at: 2026-03-12T13:09:05Z
updated_at: 2026-03-12T13:10:29Z
---

## Goal

Fix the current GitHub Actions CI failure caused by the setup-beam version/input mismatch and remove the remaining JavaScript action runtime warning.

## Todo

- [x] confirm the failing workflow annotations and supported action versions
- [x] patch ci.yml to use a compatible setup-beam reference and action runtime config
- [x] validate workflow syntax and summarize the fix
- [x] add summary and mark completed

## Summary of Changes

- Switched CI from erlef/setup-beam@v1.9 to erlef/setup-beam@v1 so the workflow can use version-file and current GitHub-hosted Ubuntu runners.
- Added FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 at the job level to opt JavaScript actions into Node 24 and clear the deprecation warning GitHub reported.
- Validated the updated workflow YAML locally.
