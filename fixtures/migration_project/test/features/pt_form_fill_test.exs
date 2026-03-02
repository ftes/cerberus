defmodule MigrationFixtureWeb.PtFormFillTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_form_fill", %{conn: conn} do
    conn
    |> visit("/search")
    |> fill_search_term("phoenix")
    |> submit_search()
    |> assert_query_text("phoenix")
  end

  defp fill_search_term(session, value) do
    PhoenixTest.fill_in(session, "Search term", with: value)
  end

  defp submit_search(session) do
    click_button(session, "Run Search")
  end

  defp assert_query_text(session, value) do
    expected = "Search query: #{value}"

    PhoenixTest.Assertions.assert_has(session, "body", text: expected)
  end
end
