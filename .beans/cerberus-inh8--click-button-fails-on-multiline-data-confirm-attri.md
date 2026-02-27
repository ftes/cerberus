---
# cerberus-inh8
title: click_button fails on multiline data-confirm attributes
status: completed
type: bug
priority: normal
created_at: 2026-02-27T21:48:20Z
updated_at: 2026-02-27T22:30:21Z
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
- [x] Add fixture button with multiline data-confirm
- [x] Add failing click_button conformance tests across drivers
- [x] Fix selector construction/escaping path for multiline attrs
- [x] Validate behavior with browser-oracle harness

## Summary of Changes

- Added a multiline `data-confirm` button case to the live selector-edge fixture.
- Added cross-driver conformance coverage (`:live` + `:browser`) for `click_button/2` with multiline `data-confirm`.
- Hardened CSS attribute escaping in `Cerberus.Driver.Html` to escape control characters (`\n`, `\r`, `\t`, `\f`) as CSS escapes when generating unique selectors.
- Added a focused Html unit test validating newline escaping and selector queryability.
- Validated behavior with targeted harness tests for live/browser parity.
