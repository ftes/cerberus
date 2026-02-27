---
# cerberus-3q56
title: 'Checkbox array fields: check/uncheck semantics for name[] groups'
status: completed
type: bug
priority: normal
created_at: 2026-02-27T21:47:54Z
updated_at: 2026-02-27T22:20:18Z
parent: cerberus-zqpu
---

Sources:
- https://github.com/germsvel/phoenix_test/issues/276
- https://github.com/germsvel/phoenix_test/issues/269

Problem:
check/uncheck behavior is incorrect for checkbox groups that use array names (e.g. name="items[]"). Reports include crashes and incorrect hidden-input handling.

Repro snippet from upstream:

```html
<input type="checkbox" name="items[]" value="one" />
```

```elixir
uncheck(conn, "Zoom")
```

Expected Cerberus parity checks:
- group checkbox lookup by label remains stable when name ends with []
- uncheck/check payloads match browser submission semantics for multi-select groups
- no hidden-input lookup crashes

## Todo
- [x] Add fixture for grouped checkbox arrays with labels
- [x] Add failing conformance tests for check/uncheck on []-named fields
- [x] Fix query/form-data merge logic for checkbox arrays
- [x] Validate static/live/browser parity with browser-oracle harness

## Summary of Changes
- Implemented `check/3` and `uncheck/3` end-to-end in Cerberus public API, assertion dispatch, option validation, and driver behaviour callbacks.
- Added checkbox field metadata (`input_type`, `input_value`, `input_checked`) to HTML field resolution so drivers can validate checkbox-only operations safely.
- Added static/live/browser driver implementations for checkbox toggling and made array-name (`name[]`) value merging robust for hidden-input + checkbox combinations.
- Updated GET submit query encoding in static/live drivers to support list values in params without crashes.
- Added new fixture coverage for checkbox arrays:
  - Static route: `/checkbox-array` and `/checkbox-array/result`.
  - Live route: `/live/checkbox-array`.
- Added cross-driver conformance harness tests in `test/core/checkbox_array_conformance_test.exs` for both `check` and `uncheck` flows across `:live/:browser` and `:static/:browser` matrices.
- Added public API tests for check/uncheck label shorthand and explicit locator validation.
