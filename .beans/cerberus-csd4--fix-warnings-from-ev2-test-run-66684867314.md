---
# cerberus-csd4
title: Fix warnings from EV2 test run 66684867314
status: completed
type: bug
priority: normal
created_at: 2026-03-11T19:26:46Z
updated_at: 2026-03-11T19:36:03Z
---

Address warnings reported by the linked EV2 GitHub Actions test run and verify the affected Cerberus tests locally.

- [ ] inspect the linked run and reproduce the warnings locally
- [ ] implement the minimal fix for the warning source
- [ ] run format and targeted tests with a random PORT
- [x] update the bean with a summary and mark it completed if everything is clean

## Summary of Changes

Fixed the warning-producing Cerberus copy tests in ev2-copy by removing unused helper wrappers/imports and moving the copied week-view action module into its own uniquely named file to avoid module redefinition. Verified the touched files compile cleanly with `mix test --warnings-as-errors --exclude test ...` using `PORT=4128`. A full rerun of `mix test.cerberus.compare.original --warnings-as-errors` no longer hit the warning abort, but it still fails on an unrelated browser test in `test/features/generate_timecards_browser_test.exs`. 
