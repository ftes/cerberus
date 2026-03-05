---
# cerberus-n9gk
title: Fix mix precommit failures
status: completed
type: bug
priority: normal
created_at: 2026-03-05T19:21:16Z
updated_at: 2026-03-05T19:37:17Z
---

Reproduce current mix precommit failures in dirty worktree, apply minimal fixes, and verify precommit passes.

## Summary of Changes
- Fixed Credo style issues by aliasing Plug.Conn.Query and Phoenix.HTML.Form in legacy and component test support modules.
- Reduced Credo complexity and nesting findings via targeted helper extraction in browser readiness flow, user context tab recovery, LiveView selector generation, and HTML label-field resolution.
- Removed unreachable data_method click branches and dead helper functions in live and static drivers to satisfy Dialyzer under current typed button and link maps.
- Kept changes minimal and behavior-preserving while making mix precommit green in the current workspace state.

## Validation
- source .envrc && PORT=4876 mix precommit

## Follow-up Pass
- Re-ran mix precommit after new local changes and fixed a new Credo nested-depth issue in trigger_live_select_option_clicks by extracting helper logic.
- Removed unreachable data_method click branches and dead helpers in live/static drivers so Dialyzer no longer reports impossible patterns and unused functions.

## Validation (Follow-up)
- source .envrc && PORT=4893 mix precommit
