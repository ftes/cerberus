defmodule MigrationFixtureWeb.PtLiveNavTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_live_nav", %{conn: conn} do
    conn
    |> visit("/live-nav")
    |> assert_step("0")
    |> click_link("Patch Step 1")
    |> assert_step("1")
    |> click_link("Navigate Counter")
    |> assert_counter_path()
    |> assert_count("0")
  end

  defp assert_step(session, value) do
    expected = "Step: #{value}"

    PhoenixTest.Assertions.assert_has(session, "#step", text: expected)
  end

  defp assert_counter_path(session) do
    PhoenixTest.assert_path(session, "/counter")
  end

  defp assert_count(session, value) do
    PhoenixTest.Assertions.assert_has(session, "#count", text: value)
  end
end
