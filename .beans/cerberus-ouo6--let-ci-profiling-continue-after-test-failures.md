---
# cerberus-ouo6
title: Let CI profiling continue after test failures
status: completed
type: task
priority: normal
created_at: 2026-03-13T08:38:34Z
updated_at: 2026-03-13T08:39:03Z
---

Adjust the manual CI profiling workflow so Chrome and Firefox profiling steps both run even if one suite fails, artifacts still upload, and the job fails at the end if either browser suite failed.\n\n- [x] let Chrome profiling continue without stopping the job immediately\n- [x] let Firefox profiling continue without stopping the job immediately\n- [x] keep artifact upload running regardless of test failures\n- [x] add a final workflow gate that fails the job if either browser suite failed

## Summary of Changes\n\n- Updated .github/workflows/ci-profile.yml so the Chrome and Firefox profiling steps both use continue-on-error and expose step outcomes via ids.\n- Kept artifact upload on if: always() so logs and profiling JSON are still collected when a suite fails.\n- Added a final Check profiling test outcomes step that fails the job if either browser profiling step did not succeed.\n- Verified the workflow still parses as YAML with ruby.
