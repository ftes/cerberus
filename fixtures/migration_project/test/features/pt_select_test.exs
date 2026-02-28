defmodule MigrationFixtureWeb.PtSelectTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  test "pt_select", %{conn: conn} do
    conn
    |> session_for_mode()
    |> visit("/select")
    |> select_role("Wizard")
    |> submit_selection()
    |> assert_selected_role("wizard")
  end

  defp session_for_mode(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end

  defp select_role(session, option_text) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.select(session, "Role", option: option_text)
      _ -> select(session, "Role", option: option_text)
    end
  end

  defp assert_selected_role(session, expected_value) do
    expected = "Selected role: #{expected_value}"

    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text(expected, exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "body", text: expected)
    end
  end

  defp submit_selection(session) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.submit(session, Cerberus.text("Apply Selection", exact: true))
      _ -> PhoenixTest.submit(session)
    end
  end
end
