---
# cerberus-efry
title: 'Cerberus v0: Vertical Slice Foundation'
status: todo
type: milestone
created_at: 2026-02-27T07:39:53Z
updated_at: 2026-02-27T07:39:53Z
---

## Goal
Ship a first usable Cerberus foundation using vertical slices, not horizontal architecture work.

## Product Outcomes
- One API style that always pipes `session -> session` (no public located-element pipeline type).
- First assertion (`assert_has`) works in **static**, **live**, and **browser** drivers.
- Cross-driver harness can run the same test spec across all drivers and report semantic drift.
- Browser driver can be used as oracle for HTML/browser behavior parity checks.

## Vertical Slice Definition (Slice 1)
- Locator capability: text-only (string/regex and simple options).
- Operation: `assert_has` and `refute_has`.
- Execution mode: one-shot only for initial slice (no retry/wait loops yet).
- Harness: run same assertions on static/live/browser fixtures and compare normalized outcomes.

## Exit Criteria
- [ ] API tests compile and pass for all 3 drivers in Slice 1.
- [ ] Harness produces one unified report per run with per-driver outcomes.
- [ ] At least one mismatch test demonstrates oracle reporting format.
- [ ] Architecture decisions captured as ADR docs and linked from beans.
