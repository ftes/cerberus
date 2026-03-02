defmodule MigrationFixtureWeb.PtTextAssertTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_text_assert", %{conn: conn} do
    conn
    |> visit("/")
    |> assert_counter_link()
  end

  defp assert_counter_link(session) do
    PhoenixTest.Assertions.assert_has(session, "a", text: "Counter")
  end
end
