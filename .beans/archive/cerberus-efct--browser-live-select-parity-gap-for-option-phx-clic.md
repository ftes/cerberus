---
# cerberus-efct
title: Browser live select parity gap for option phx-click and repeated multi-select
status: completed
type: bug
priority: normal
created_at: 2026-03-05T19:36:00Z
updated_at: 2026-03-05T20:01:57Z
parent: cerberus-zh82
---

## Problem
Browser driver does not currently match live driver behavior for two newly fixed PT parity flows.

## Broken Behavior
- Selecting options in the non-form select under /phoenix_test/live/index does not dispatch option phx-click effects in browser mode, so selected: [dog, cat] is never rendered.
- Repeated select calls on the Race 2 multi-select in browser mode do not produce cumulative submit payload [elf, dwarf] after Save Full Form.

## Evidence
- Command: source .envrc && PORT=4353 mix test test/cerberus/helper_locator_behavior_test.exs:302 test/cerberus/helper_locator_behavior_test.exs:312
- Phoenix driver variants pass; browser variants fail with missing selected: [dog, cat] and missing [elf, dwarf] assertions.

## Conceptual Reproduction
1. Start browser session and visit /phoenix_test/live/index.
2. Within #not-a-form, select Choose a pet option Dog and Cat.
3. Observe form-data does not show selected: [dog, cat] in browser mode.
4. On the same page, select Race 2 with Elf then Dwarf in repeated calls, click Save Full Form.
5. Observe form-data does not include [elf, dwarf] in browser mode.

## Suspected Root Cause
Browser action helper select path likely sets DOM selected state but does not mirror the same event dispatch semantics as live driver for option-level phx-click and repeated multi-select accumulation.

## Proposed Fix
- Align browser select action semantics with live semantics for non-form option phx-click dispatch.
- Ensure repeated multi-select calls merge and preserve previously selected values for subsequent submits.
- Add first-class browser regression coverage for both flows.

## Summary of Changes
- Reproduced browser-only live select parity failures with first-class browser variants in test/cerberus/live_select_regression_test.exs.
- Added browser regression coverage for:
  - live multi-select repeated scalar calls preserving cumulative values.
  - outside-form select option phx-click dispatch.
- Fixed browser action helper select semantics:
  - Added optionListInput payload from browser driver to preserve scalar-vs-list intent.
  - For multi-select, preserve cached prior selections on repeated scalar select calls.
  - Added per-path multi-select cache invalidation to avoid stale carry-over.
  - Dispatch click events for matched option elements with phx-click bindings.
- Verified:
  - PORT=4365 mix test test/cerberus/live_select_regression_test.exs (6 tests, 0 failures)
  - PORT=4366 mix test combined first-class regression files (15 tests, 0 failures)
  - PORT=4367 mix test test/cerberus/phoenix_test (372 tests, 0 failures, 4 skipped)
