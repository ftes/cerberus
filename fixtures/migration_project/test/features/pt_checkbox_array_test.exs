defmodule MigrationFixtureWeb.PtCheckboxArrayTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  test "pt_checkbox_array", %{conn: conn} do
    checked =
      conn
      |> session_for_mode()
      |> visit("/checkbox")
      |> check("Two")
      |> submit_items()

    assert_selected_items(checked, "one,two")

    unchecked =
      conn
      |> session_for_mode()
      |> visit("/checkbox")
      |> check("Two")
      |> uncheck("Two")
      |> submit_items()

    assert_selected_items(unchecked, "one")
  end

  defp session_for_mode(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end

  defp assert_selected_items(session, items) do
    expected = "Selected Items: #{items}"

    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text(expected, exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "body", text: expected)
    end
  end

  defp submit_items(session) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.submit(session, Cerberus.text("Save Items", exact: true))
      _ -> PhoenixTest.submit(session)
    end
  end
end
