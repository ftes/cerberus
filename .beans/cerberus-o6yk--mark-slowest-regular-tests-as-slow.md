---
# cerberus-o6yk
title: Mark slowest regular tests as slow
status: completed
type: task
priority: normal
created_at: 2026-03-07T06:18:08Z
updated_at: 2026-03-07T06:20:18Z
---

Tag the previously identified slowest regular test cases with :slow.

## Todo
- [x] Add :slow tags to the identified regular-test outliers
- [x] Format touched files
- [x] Run targeted --include slow checks
- [x] Update bean summary and complete it

## Summary of Changes
- Marked the previously identified regular-lane outliers as :slow.
- Used module-level :slow tags for the fully slow browser-only files covering browser multi-session behavior, popup mode, and explicit browser startup semantics.
- Used targeted per-test :slow tags for the slower browser rows in mixed files, including the browser init-script/new-tab test, browser candidate-hint failure diagnostics, the docs multi-user/multi-tab browser row, the browser missing-field value-assertion row, and the browser live multi-select regression row.
- Verified the tagged tests with --include slow and confirmed on a follow-up mix test --slowest 20 run that the tagged rows now appear as excluded from the regular lane.
