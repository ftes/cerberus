defmodule MigrationFixtureWeb.PtLiveClickTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_live_click", %{conn: conn} do
    conn
    |> visit("/")
    |> click_link("Counter")
    |> click_button("Increment")
    |> assert_count("1")
  end

  defp assert_count(session, expected_text) do
    PhoenixTest.Assertions.assert_has(session, "#count", text: expected_text)
  end
end
