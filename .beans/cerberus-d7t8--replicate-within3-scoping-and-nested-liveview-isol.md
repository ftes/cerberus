---
# cerberus-d7t8
title: Replicate within/3 scoping and nested LiveView isolation quirks
status: todo
type: task
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T11:31:31Z
parent: cerberus-zqpu
---

## Scope
Replicate `within/3` scoping semantics for nested LiveViews, including isolation between parent and child components and scoped failure behavior.

## PhoenixTest Source Snippet
`/tmp/phoenix_test/test/phoenix_test/live_test.exs`

```elixir
test "can target subsequent calls to nested liveview", %{conn: conn} do
  conn
  |> visit("/live/nested")
  |> within("#child-live-view", fn session ->
    session
    |> fill_in("Email", with: "someone@example.com")
    |> click_button("Save")
    |> assert_has("#child-view-form-data", text: "email: someone@example.com")
  end)
  |> refute_has("#parent-view-form-data", text: "email: someone@example.com")
end

test "raises when data is not in scoped HTML", %{conn: conn} do
  assert_raise ArgumentError, ~r/Could not find element with label "User Name"/, fn ->
    conn
    |> visit("/live/index")
    |> within("#email-form", fn session ->
      fill_in(session, "User Name", with: "Aragorn")
    end)
  end
end
```

## Done When
- [ ] Scope stack is preserved across nested `within` calls.
- [ ] Child LiveView actions remain isolated from parent state.
- [ ] Scoped-not-found errors are explicit and tested.
