---
# cerberus-bgq4
title: Add rich locator state filters
status: completed
type: feature
priority: normal
created_at: 2026-03-01T16:00:44Z
updated_at: 2026-03-01T21:33:56Z
blocked_by:
    - cerberus-1xnx
---

Add stateful locator constraints (checked/unchecked, disabled/enabled, selected, readonly/editable, visible/hidden) across Static, Live, and Browser implementations with conformance tests.

## Prerequisite
- Complete cerberus-1xnx rich locator oracle corpus updates first; preserve and extend that corpus as this bean lands.

## Summary of Changes

- Added state filter support in operation options: checked, disabled, selected, readonly.
- Implemented shared state filter matching in Cerberus.Query and applied it in static, live, and browser candidate matching paths.
- Extended HTML and LiveView candidate maps with state metadata so filters can be evaluated consistently.
- Extended browser expression payloads for clickables and form/file fields with state metadata and wired filtering before match selection.
- Added and updated coverage in options_test, locator_parity_test, and helper_locator_behavior_test for selected and disabled filter behavior across drivers.
