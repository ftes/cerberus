defmodule MigrationFixtureWeb.PtLiveAsyncTimeoutTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  test "pt_live_async_timeout", %{conn: conn} do
    conn
    |> session_for_mode()
    |> visit("/live-async")
    |> click_button("Start Async")
    |> assert_async_done()
  end

  defp session_for_mode(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end

  defp assert_async_done(session) do
    expected = "Async Status: done"

    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" ->
        Cerberus.assert_has(session, Cerberus.text(expected, exact: true), timeout: 200)

      _ ->
        PhoenixTest.assert_has(session, "#async-status", text: expected, timeout: 200)
    end
  end
end
