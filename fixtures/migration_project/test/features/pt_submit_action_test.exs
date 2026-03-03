defmodule MigrationFixtureWeb.PtSubmitActionTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_submit_action", %{conn: conn} do
    conn
    |> visit("/search")
    |> fill_search_term("elixir")
    |> submit()
    |> assert_results_path()
    |> assert_query_text("elixir")
    |> assert_submit_source("search_button")
  end

  defp fill_search_term(session, value) do
    PhoenixTest.fill_in(session, "Search term", with: value)
  end

  defp assert_results_path(session) do
    PhoenixTest.assert_path(session, "/search/results")
  end

  defp assert_query_text(session, value) do
    expected = "Search query: #{value}"

    PhoenixTest.Assertions.assert_has(session, "body", text: expected)
  end

  defp assert_submit_source(session, value) do
    expected = "Submit source: #{value}"

    PhoenixTest.Assertions.assert_has(session, "body", text: expected)
  end
end
