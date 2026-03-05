---
# cerberus-0nud
title: Fix precommit after PT parity updates
status: completed
type: bug
priority: normal
created_at: 2026-03-05T20:03:50Z
updated_at: 2026-03-05T20:06:57Z
parent: cerberus-zh82
---

## Problem
Current working tree likely fails mix precommit after recent PhoenixTest parity and browser fixes.

## Plan
1. Run source .envrc && mix precommit.
2. Fix all failing checks.
3. Re-run precommit until green.
4. Record summary of fixes and verification.

## Summary of Changes
- Ran source .envrc && PORT=4368 mix precommit.
- Precommit initially failed on Credo complexity/nesting in new parity code.
- Refactored nested/complex functions into helper branches without behavior changes:
  - lib/cerberus/phoenix/live_view_html.ex
  - lib/cerberus/driver/static.ex
  - lib/cerberus/driver/live.ex
- Re-ran precommit and fixed one dialyzer warning in lib/cerberus/driver/static.ex by removing unreachable normalize_submit_method/1 fallback clause.
- Re-ran source .envrc && PORT=4368 mix precommit; all checks passed (Credo, Dialyzer, docs generation).
