---
# cerberus-inh8
title: click_button fails on multiline data-confirm attributes
status: todo
type: bug
created_at: 2026-02-27T21:48:20Z
updated_at: 2026-02-27T21:48:20Z
parent: cerberus-zqpu
---

Sources:
- https://github.com/germsvel/phoenix_test/issues/205

Problem:
click_button/2 fails when a button has a multiline data-confirm attribute; selector generation/escaping does not match browser DOM/query semantics.

Repro snippet from upstream:

```html
<button data-confirm={"Are you sure?\nMore text"}>
  Create
</button>
```

```elixir
|> click_button("Create")
```

Error reported upstream:
Could not find element with selector "button[data-confirm=\"Are you sure?\\nMore text\"]" and text "Create".

Expected Cerberus parity checks:
- multiline attribute values do not break button lookup
- locator escaping/normalization is robust for newline-containing attributes

## Todo
- [ ] Add fixture button with multiline data-confirm
- [ ] Add failing click_button conformance tests across drivers
- [ ] Fix selector construction/escaping path for multiline attrs
- [ ] Validate behavior with browser-oracle harness
