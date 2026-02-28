defmodule MigrationFixtureWeb.PtPathRefuteTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  test "pt_path_refute", %{conn: conn} do
    conn
    |> session_for_mode()
    |> visit("/")
    |> click_link("Counter")
    |> refute_path("/not-counter")
  end

  defp session_for_mode(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end
end
