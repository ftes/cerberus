defmodule MigrationFixtureWeb.PtLiveAsyncTimeoutTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_live_async_timeout", %{conn: conn} do
    conn
    |> visit("/live-async")
    |> click_button("Start Async")
    |> assert_async_done()
  end

  defp assert_async_done(session) do
    expected = "Async Status: done"

    PhoenixTest.assert_has(session, "#async-status", text: expected, timeout: 200)
  end
end
