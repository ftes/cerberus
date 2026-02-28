---
# cerberus-6i8f
title: Replicate LiveView upload edge-case behavior from phoenix_test
status: completed
type: task
priority: normal
created_at: 2026-02-27T11:31:31Z
updated_at: 2026-02-27T21:40:01Z
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
- [x] Upload behavior matches active-form semantics (upload alone does not imply submit-able active form).
- [x] Error translation exists for upload failures (`:not_accepted`, `:too_many_files`, `:too_large`).
- [x] Upload-triggered change and redirect flows are integration-tested.

## Summary of Changes
- Added first-class `upload/4` API and locator normalization with explicit label semantics (string/regex shorthand, `label(...)`, and `css(...)`).
- Implemented live-driver upload behavior with translated upload errors (`:not_accepted`, `:too_many_files`, `:too_large`), form phx-change triggering, and redirect/patch handling.
- Implemented browser-driver upload behavior by setting file inputs through in-page file synthesis and dispatching input/change events.
- Added upload fixture LiveView and file fixtures to cover change-trigger and progress-redirect behavior.
- Added conformance and public API tests for upload semantics and edge-case parity.
