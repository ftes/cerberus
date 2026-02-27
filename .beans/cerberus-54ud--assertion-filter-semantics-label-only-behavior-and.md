---
# cerberus-54ud
title: 'Assertion filter semantics: label-only behavior and option validation'
status: completed
type: bug
priority: normal
created_at: 2026-02-27T21:47:43Z
updated_at: 2026-02-27T22:35:41Z
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
- [x] Add cross-driver failing conformance tests for label-only assert/refute behavior
- [x] Add argument validation tests for assert/refute option keys
- [x] Implement fixes in shared assertion/query path
- [x] Verify with browser-oracle coverage

## Summary of Changes
Updated shared assertion locator normalization so label locators in assert_has and refute_has are treated as text assertions instead of being rejected.
Added cross-driver conformance tests for label-only assert/refute behavior, including failure semantics for missing labels and passing refutations.
Added tests that assert_has and refute_has reject unknown option keys with explicit invalid options errors.
Updated README locator helper notes to document label behavior for assertions.
Validated with focused tests and mix precommit.

## Triage Note
This candidate comes from an upstream phoenix_test issue or PR and may already work in Cerberus.
If current Cerberus behavior already matches the expected semantics, add or keep the conformance test coverage and close this bean as done (no behavior change required).
