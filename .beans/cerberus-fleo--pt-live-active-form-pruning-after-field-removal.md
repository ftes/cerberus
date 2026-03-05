---
# cerberus-fleo
title: PT live active form pruning after field removal
status: todo
type: bug
priority: normal
created_at: 2026-03-05T14:14:57Z
updated_at: 2026-03-05T14:14:57Z
parent: cerberus-zh82
---

## Problem
Active form snapshot can become stale after conditional field removal, causing submit parity mismatch.

## Broken Behavior
- test/cerberus/phoenix_test/live_test.exs line 1105 is skipped.
- Scenario fills two fields, submits, toggles visibility to remove one field, submits again.
- Expected: remaining field persists and removed field is not submitted.

## Suspected Root Cause
Active form state appears to retain removed field entries and submit path does not prune against current DOM before payload generation.

## Proposed Fix
1. Reconcile active form fields against current rendered DOM right before submit.
2. Drop removed fields from payload while preserving defaults and hidden companions that still exist.
3. Ensure reconciliation runs for both direct submit and click_button submit paths.

## Implementation Targets
- lib/cerberus/driver/live.ex
- active form state helper modules if separate

## Acceptance
- Unskip line 1105 in live_test.
- Add first-class regression test outside import suite for field removal before submit.
