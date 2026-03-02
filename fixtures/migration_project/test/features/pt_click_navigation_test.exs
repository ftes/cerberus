defmodule MigrationFixtureWeb.PtClickNavigationTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_click_navigation", %{conn: conn} do
    conn
    |> visit("/")
    |> click_link("Counter")
    |> assert_count("0")
  end

  defp assert_count(session, expected_text) do
    PhoenixTest.Assertions.assert_has(session, "#count", text: expected_text)
  end
end
