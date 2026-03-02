---
# cerberus-faey
title: Fix CI test filter warning and Chrome userns sandbox EPERM
status: completed
type: bug
priority: normal
created_at: 2026-03-02T05:50:58Z
updated_at: 2026-03-02T05:59:32Z
---

## Problem
CI emits a test file filter warning for benchmark file and fails browser startup with user namespace EPERM.

## TODO
- [x] Reproduce failing warning and sandbox error locally
- [x] Fix test pattern/load-ignore config for benchmark test files
- [x] Fix browser launch behavior for environments without user namespaces
- [x] Run format and targeted tests
- [x] Run precommit
- [x] Add summary of changes

## Summary of Changes
- Moved the browser locator benchmark script from `test/bench/` to `bench/` so `mix test` no longer warns about a non-test `.exs` file under `test/`.
- Updated the benchmark script to require `test/test_helper.exs` from its new location.
- Hardened test browser configuration by adding Chrome args for constrained CI/container environments: `--no-sandbox`, `--disable-setuid-sandbox`, and `--disable-dev-shm-usage`.
- Verified with `mix format`, `mix test --warnings-as-errors --max-failures 1`, `MIX_ENV=test mix run bench/browser_locator_assertion_paths_benchmark.exs --sizes 10 --iterations 1 --warmup 0`, and `mix precommit`.
