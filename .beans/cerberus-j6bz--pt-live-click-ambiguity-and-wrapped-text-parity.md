---
# cerberus-j6bz
title: PT live click ambiguity and wrapped text parity
status: todo
type: bug
priority: normal
created_at: 2026-03-05T14:14:17Z
updated_at: 2026-03-05T14:14:56Z
parent: cerberus-zh82
---

## Problem
Imported PhoenixTest live integration cases remain skipped around click locator ambiguity and wrapped text handling.

## Broken Behavior
- test/cerberus/phoenix_test/live_test.exs line 113: click_link with duplicate text should raise an ambiguity error but does not match upstream behavior.
- test/cerberus/phoenix_test/live_test.exs line 327: click_button cannot reliably target button text wrapped in nested tags.
- test/cerberus/phoenix_test/live_test.exs line 334: click_button with explicit selector and wrapped id still collides with duplicate text matches.

## Suspected Root Cause
Live click matching appears to apply text filtering before selector narrowing and does not normalize visible text across nested children in a parity-compatible way.

## Proposed Fix
1. In live click resolution, apply explicit selector narrowing first, then text filter within that narrowed set.
2. Normalize node text extraction for wrapped content so nested span text is treated as button or link text.
3. When multiple nodes remain after filtering, raise deterministic ambiguity error including match count.
4. Keep behavior aligned between click_link and click_button.

## Implementation Targets
- lib/cerberus/driver/live.ex
- any live locator helper used by click actions

## Acceptance
- Unskip the three tests listed above in live_test.
- mix test test/cerberus/phoenix_test/live_test.exs:113
- mix test test/cerberus/phoenix_test/live_test.exs:327
- mix test test/cerberus/phoenix_test/live_test.exs:334
- Add first-class regression coverage outside phoenix_test import tree.
