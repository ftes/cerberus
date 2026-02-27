---
# cerberus-3q56
title: 'Checkbox array fields: check/uncheck semantics for name[] groups'
status: todo
type: bug
created_at: 2026-02-27T21:47:54Z
updated_at: 2026-02-27T21:47:54Z
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
- [ ] Add fixture for grouped checkbox arrays with labels
- [ ] Add failing conformance tests for check/uncheck on []-named fields
- [ ] Fix query/form-data merge logic for checkbox arrays
- [ ] Validate static/live/browser parity with browser-oracle harness
