defmodule MigrationFixtureWeb.PtPathAssertTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_path_assert", %{conn: conn} do
    conn
    |> visit("/")
    |> click_link("Counter")
    |> assert_path("/counter")
  end
end
