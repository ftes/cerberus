---
# cerberus-54ud
title: 'Assertion filter semantics: label-only behavior and option validation'
status: todo
type: bug
created_at: 2026-02-27T21:47:43Z
updated_at: 2026-02-27T21:47:43Z
parent: cerberus-zqpu
---

Sources:
- https://github.com/germsvel/phoenix_test/issues/285
- https://github.com/germsvel/phoenix_test/pull/286
- https://github.com/germsvel/phoenix_test/issues/291

Problem:
Assertion filtering around label/value is inconsistent:
1) label-only queries can behave incorrectly when value is omitted (#285).
2) assert_has/refute_has accept unknown options silently (e.g. with: instead of text:) (#291).

Repro / failing tests from upstream:

```elixir
# #286
test "assert by label raises an error if label not found", %{conn: conn} do
  assert_raise AssertionError, fn ->
    conn
    |> visit("/page/by_value")
    |> assert_has("input", label: "Unknown")
  end
end

test "refute by label", %{conn: conn} do
  conn
  |> visit("/page/by_value")
  |> refute_has("input", label: "Unknown")
end
```

```elixir
# #291
|> assert_has("p", with: "...") # typo: should be text:
```

Expected Cerberus parity checks:
- label-only filtering in assert_has/refute_has matches browser intent.
- invalid option keys are rejected with explicit errors.

## Todo
- [ ] Add cross-driver failing conformance tests for label-only assert/refute behavior
- [ ] Add argument validation tests for assert/refute option keys
- [ ] Implement fixes in shared assertion/query path
- [ ] Verify with browser-oracle coverage
