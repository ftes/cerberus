defmodule MigrationFixtureWeb.PtPathRefuteTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_path_refute", %{conn: conn} do
    conn
    |> visit("/")
    |> click_link("Counter")
    |> refute_path("/not-counter")
  end
end
