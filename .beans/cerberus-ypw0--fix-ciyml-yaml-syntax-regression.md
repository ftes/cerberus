---
# cerberus-ypw0
title: Fix ci.yml YAML syntax regression
status: completed
type: bug
priority: normal
created_at: 2026-03-12T08:55:25Z
updated_at: 2026-03-12T08:58:58Z
---

## Goal

Fix the GitHub Actions workflow syntax error in .github/workflows/ci.yml so CI loads again.

## Todo

- [x] Inspect the failing workflow block and identify the YAML/schema issue
- [x] Patch .github/workflows/ci.yml with the minimal safe fix
- [x] Validate the workflow file locally
- [x] Add a summary of changes and complete the bean if all todo items are done

## Summary of Changes

- Switched the browser version handoff in .github/workflows/ci.yml from $GITHUB_ENV to explicit step outputs.
- Updated the browser runtime cache key to read from steps.browser_env.outputs instead of env variables populated at runtime.
- Validated the workflow locally with YAML parsing and actionlint.
