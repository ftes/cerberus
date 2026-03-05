---
# cerberus-373l
title: Continue EV2-copy shim trial
status: completed
type: task
priority: normal
created_at: 2026-03-05T09:41:19Z
updated_at: 2026-03-05T10:36:36Z
---

## Goal
Continue real-world shim trial in ../ev2-copy across remaining PhoenixTest-style test modules.

## Todo
- [x] Enumerate non-Playwright candidate test files
- [x] Run one-by-one shim swap + test execution
- [x] Summarize failures and passing set

## Summary of Changes
- Re-ran full non-Playwright shim candidate sweep in ../ev2-copy (60 files) with per-file runs.
- Improved result from 27 pass / 33 fail to 32 pass / 28 fail in latest full sweep (/tmp/ev2copy_shim_loop_20260305_112926).
- Added/iterated EV2 test-only shim compat changes: Plug.Conn/session handling, :at stripping for assert ops, upload fallback to file input selector, static click_button submit fallback, role fallback for check/uncheck/choose, and legacy label normalization for assert label option.
- Added EV2 test-only adjustments removing PhoenixTest active_form internals usage in offer_new and required_templates tests.
- Patched Cerberus live driver click paths: pass %{} to render_click/2 and ignore blank data_method so only non-empty data-method links/buttons use data-method path.
- Residual top failures are now mostly assert_has mismatches/timeouts, a few check/role misses in distro member pickers, and static/controller behavior differences.
