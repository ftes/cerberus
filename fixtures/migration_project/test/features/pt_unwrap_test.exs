defmodule MigrationFixtureWeb.PtUnwrapTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  test "pt_unwrap", %{conn: conn} do
    conn
    |> session_for_mode()
    |> visit("/search")
    |> unwrap(fn native ->
      Phoenix.ConnTest.get(native, "/search/results?q=wrapped")
    end)
    |> assert_query_text("wrapped")
    |> visit("/counter")
    |> unwrap(fn view ->
      view
      |> Phoenix.LiveViewTest.element("button", "Increment")
      |> Phoenix.LiveViewTest.render_click()
    end)
    |> assert_count("1")
  end

  defp session_for_mode(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end

  defp assert_query_text(session, value) do
    expected = "Search query: #{value}"

    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text(expected, exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "body", text: expected)
    end
  end

  defp assert_count(session, value) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text(value, exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "#count", text: value)
    end
  end
end
