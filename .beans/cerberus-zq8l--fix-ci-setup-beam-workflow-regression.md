---
# cerberus-zq8l
title: Fix CI setup-beam workflow regression
status: in-progress
type: bug
priority: normal
created_at: 2026-03-12T13:09:05Z
updated_at: 2026-03-12T13:09:52Z
---

## Goal

Fix the current GitHub Actions CI failure caused by the setup-beam version/input mismatch and remove the remaining JavaScript action runtime warning.

## Todo

- [x] confirm the failing workflow annotations and supported action versions
- [x] patch ci.yml to use a compatible setup-beam reference and action runtime config
- [ ] validate workflow syntax and summarize the fix
- [ ] add summary and mark completed
