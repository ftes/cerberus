defmodule MigrationFixtureWeb.PtTextAssertTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  test "pt_text_assert", %{conn: conn} do
    conn
    |> session_for_mode()
    |> visit("/")
    |> assert_counter_link()
  end

  defp session_for_mode(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end

  defp assert_counter_link(session) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text("Counter", exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "a", text: "Counter")
    end
  end
end
