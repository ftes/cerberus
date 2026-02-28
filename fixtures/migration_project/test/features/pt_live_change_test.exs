defmodule MigrationFixtureWeb.PtLiveChangeTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  test "pt_live_change", %{conn: conn} do
    conn
    |> session_for_mode()
    |> visit("/live-change")
    |> fill_name("Aragorn")
    |> assert_change("Aragorn")
  end

  defp session_for_mode(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end

  defp fill_name(session, value) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.fill_in(session, "Name", value)
      _ -> PhoenixTest.fill_in(session, "Name", with: value)
    end
  end

  defp assert_change(session, value) do
    expected = "Changed: #{value}"

    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text(expected, exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "#change-result", text: expected)
    end
  end
end
