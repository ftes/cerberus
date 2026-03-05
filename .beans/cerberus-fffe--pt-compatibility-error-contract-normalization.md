---
# cerberus-fffe
title: PT compatibility error contract normalization
status: todo
type: bug
priority: normal
created_at: 2026-03-05T14:14:57Z
updated_at: 2026-03-05T14:14:57Z
parent: cerberus-zh82
---

## Problem
Current PT live suite has active failures from exception contract drift in negative click_button scenarios.

## Broken Behavior
Latest run shows failures in test/cerberus/phoenix_test/live_test.exs:
- line 263 expected AssertionError but got ArgumentError for invalid non-submit button JS command.
- line 273 expected AssertionError but got ArgumentError for disabled button.
- line 302 expected AssertionError but got ArgumentError for actionless button without phx-click.

Additional static contract drift exists around data-method error expectations in test/cerberus/phoenix_test/static_test.exs lines 201 and 257.

## Suspected Root Cause
Compatibility layer no longer normalizes low-level live driver ArgumentError into assertion-facing AssertionError contracts used by imported PT tests.

## Proposed Fix
1. Define a clear compatibility error contract at PT adapter boundary:
   - action failures surface as AssertionError with actionable message.
2. Wrap low-level ArgumentError and re-raise AssertionError in PT compatibility adapters where appropriate.
3. Align static data-method negative expectations with current intended behavior or adjust adapter contract consistently.
4. Keep helpful wording checks gist-based, not brittle full-string matches.

## Implementation Targets
- test/support/phoenix_test/legacy.ex
- test/support/phoenix_test/driver.ex
- possibly lib/cerberus/driver/live.ex for error normalization points

## Acceptance
- PT aggregate run no longer fails on the listed lines.
- Keep semantics-correct failures while normalizing exception class and message usefulness.
