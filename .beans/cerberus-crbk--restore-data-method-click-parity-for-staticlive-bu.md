---
# cerberus-crbk
title: Restore data-method click parity for static/live buttons
status: completed
type: bug
priority: normal
created_at: 2026-03-05T19:48:55Z
updated_at: 2026-03-05T19:56:37Z
parent: cerberus-zh82
---

## Problem
PT parity regressed for data-method clicks. In current tree, drivers expose data_method/data_to metadata from HTML matching but neither static nor live click paths execute data-method requests.

## Broken behavior
- test/cerberus/phoenix_test/live_test.exs:255 fails: click_button("Data-method Delete") returns no button matched locator.
- test/cerberus/phoenix_test/static_test.exs:201 fails: static driver reports button clicks unsupported.
- test/cerberus/phoenix_test/static_test.exs:256 fails wrong contract for incomplete data-method button (expected helpful data-to/href message).

## Plan
1. Add explicit data-method handling branch for click_button in static and live drivers.
2. Preserve existing link fallback behavior where no data-to is present.
3. Reuse existing follow_form_request plumbing to issue request with normalized method.
4. Return assertion-friendly error when data-method exists but target is missing.

## Acceptance
- Data-method button tests above pass in both static/live suites.
- No regressions in nearby live checkbox parity tests.

## Summary of Changes
- Restored data-method click parity for static and live drivers.
- Static driver:
  - Added explicit data-method click handling for buttons.
  - Preserved link fallback behavior when data-to is missing.
  - Added contract error message for missing target: data-method element must define data-to or href.
- Live driver:
  - Added explicit data-method handling for click_link/click_button when running on live routes.
  - Kept existing non-data-method click behavior unchanged.
- Added first-class regression coverage in test/cerberus/data_method_click_behavior_test.exs for static/live button flows and missing-target error contract.
- Verified with targeted tests:
  - PORT=4353 mix test live/static data-method parity locations
  - regression tests pass.
