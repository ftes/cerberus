---
# cerberus-efct
title: Browser live select parity gap for option phx-click and repeated multi-select
status: todo
type: bug
priority: normal
created_at: 2026-03-05T19:36:00Z
updated_at: 2026-03-05T19:36:03Z
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
