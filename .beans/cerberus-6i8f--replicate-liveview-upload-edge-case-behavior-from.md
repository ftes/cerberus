---
# cerberus-6i8f
title: Replicate LiveView upload edge-case behavior from phoenix_test
status: todo
type: task
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T11:31:31Z
parent: cerberus-zqpu
---

## Scope
Replicate LiveView upload quirks: upload-only active-form behavior, user-friendly upload errors, phx-change validation on file select, and redirects from upload progress callbacks.

## PhoenixTest Source Snippet
`/tmp/phoenix_test/test/phoenix_test/live_test.exs`

```elixir
test "upload (without other form actions) does not work with submit (matches browser behavior)", %{conn: conn} do
  session =
    conn
    |> visit("/live/index")
    |> within("#full-form", fn session ->
      upload(session, "Avatar", "test/files/elixir.jpg")
    end)

  assert_raise ArgumentError, ~r/no active form/, fn ->
    submit(session)
  end
end

test "triggers phx-change validations upon file selection", %{conn: conn} do
  conn
  |> visit("/live/index")
  |> within("#upload-change-form", fn session ->
    upload(session, "Avatar", "test/files/elixir.jpg")
  end)
  |> assert_has("#upload-change-result", text: "phx-change triggered on file selection")
end

test "follows redirects from `:progress` events", %{conn: conn} do
  conn
  |> visit("/live/index")
  |> within("#upload-redirect-form", fn session ->
    upload(session, "Redirect Avatar", "test/files/elixir.jpg")
  end)
  |> assert_path("/live/page_2")
end
```

## Done When
- [ ] Upload behavior matches active-form semantics (upload alone does not imply submit-able active form).
- [ ] Error translation exists for upload failures (`:not_accepted`, `:too_many_files`, `:too_large`).
- [ ] Upload-triggered change and redirect flows are integration-tested.
