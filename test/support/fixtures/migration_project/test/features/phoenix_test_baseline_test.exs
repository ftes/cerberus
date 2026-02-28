defmodule MigrationFixtureWeb.PhoenixTestBaselineTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "phoenix_test static and live flow", %{conn: conn} do
    conn
    |> visit("/")
    |> assert_has("h1", text: "Migration fixture")
    |> click_link("Counter")
    |> assert_has("body .phx-connected")
    |> assert_has("#count", text: "0")
    |> click_button("Increment")
    |> assert_has("#count", text: "1")
  end
end
