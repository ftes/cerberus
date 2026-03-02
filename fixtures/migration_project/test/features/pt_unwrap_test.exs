defmodule MigrationFixtureWeb.PtUnwrapTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_unwrap", %{conn: conn} do
    conn
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

  defp assert_query_text(session, value) do
    expected = "Search query: #{value}"

    PhoenixTest.Assertions.assert_has(session, "body", text: expected)
  end

  defp assert_count(session, value) do
    PhoenixTest.Assertions.assert_has(session, "#count", text: value)
  end
end
