defmodule MigrationFixtureWeb.PtStaticNavTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_static_nav", %{conn: conn} do
    conn
    |> visit("/")
    |> assert_title("Migration fixture")
  end

  defp assert_title(session, expected_text) do
    PhoenixTest.Assertions.assert_has(session, "h1", text: expected_text)
  end
end
