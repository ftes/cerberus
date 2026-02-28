defmodule MigrationFixtureWeb.PtSubmitActionTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  @mode_env "CERBERUS_MIGRATION_FIXTURE_MODE"

  test "pt_submit_action", %{conn: conn} do
    conn
    |> session_for_mode()
    |> visit("/search")
    |> fill_search_term("elixir")
    |> submit_search()
    |> assert_results_path()
    |> assert_query_text("elixir")
  end

  defp session_for_mode(conn) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.session(endpoint: MigrationFixtureWeb.Endpoint)
      _ -> conn
    end
  end

  defp fill_search_term(session, value) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.fill_in(session, "Search term", value)
      _ -> PhoenixTest.fill_in(session, "Search term", with: value)
    end
  end

  defp submit_search(session) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.submit(session, Cerberus.text("Run Search", exact: true))
      _ -> PhoenixTest.submit(session)
    end
  end

  defp assert_results_path(session) do
    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_path(session, "/search/results")
      _ -> PhoenixTest.assert_path(session, "/search/results")
    end
  end

  defp assert_query_text(session, value) do
    expected = "Search query: #{value}"

    case System.get_env(@mode_env, "phoenix_test") do
      "cerberus" -> Cerberus.assert_has(session, Cerberus.text(expected, exact: true))
      _ -> PhoenixTest.Assertions.assert_has(session, "body", text: expected)
    end
  end
end
