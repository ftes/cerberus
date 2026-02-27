---
# cerberus-vwc7
title: Override Hex package name to fluffy
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:06:49Z
updated_at: 2026-02-27T11:07:26Z
---

Use hex.pm package name fluffy while keeping app/module names unchanged.

## Todo
- [x] Add package name override in mix.exs package() metadata
- [x] Verify formatting/tests still pass

## Summary of Changes
- Updated package metadata in mix.exs to set Hex package name override: `name: "fluffy"`.
- Kept app/module naming unchanged (`:cerberus`, `Cerberus`).
- Verified formatting with `mix format --check-formatted mix.exs`.
- Ran `mix test`; initial run hit a transient browser context error, rerun passed (23 tests, 0 failures).
