defmodule MigrationFixtureWeb.PtTextRefuteTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  test "pt_text_refute", %{conn: conn} do
    conn
    |> session_for_mode()
    |> visit("/")
    |> refute_missing_text("Does not exist")
  end

  defp session_for_mode(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end

  defp refute_missing_text(session, expected_text) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.refute_has(session, Cerberus.text(expected_text, exact: true))
      _ -> PhoenixTest.Assertions.refute_has(session, "body", text: expected_text)
    end
  end
end
