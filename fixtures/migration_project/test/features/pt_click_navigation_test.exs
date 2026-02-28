defmodule MigrationFixtureWeb.PtClickNavigationTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  test "pt_click_navigation", %{conn: conn} do
    conn
    |> session_for_mode()
    |> visit("/")
    |> click_link("Counter")
    |> assert_count("0")
  end

  defp session_for_mode(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end

  defp assert_count(session, expected_text) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text(expected_text, exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "#count", text: expected_text)
    end
  end
end
