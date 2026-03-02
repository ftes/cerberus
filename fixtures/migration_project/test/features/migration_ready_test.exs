defmodule MigrationFixtureWeb.MigrationReadyTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "single flow can run pre and post migration", %{conn: conn} do
    conn
    |> visit("/")
    |> assert_title("Migration fixture")
    |> click_link("Counter")
    |> assert_count("0")
    |> click_button("Increment")
    |> assert_count("1")
  end

  defp assert_title(session, expected_text) do
    PhoenixTest.Assertions.assert_has(session, "h1", text: expected_text)
  end

  defp assert_count(session, expected_text) do
    PhoenixTest.Assertions.assert_has(session, "#count", text: expected_text)
  end
end
