defmodule MigrationFixtureWeb.PtLiveChangeTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_live_change", %{conn: conn} do
    conn
    |> visit("/live-change")
    |> fill_name("Aragorn")
    |> assert_change("Aragorn")
  end

  defp fill_name(session, value) do
    PhoenixTest.fill_in(session, "Name", with: value)
  end

  defp assert_change(session, value) do
    expected = "Changed: #{value}"

    PhoenixTest.Assertions.assert_has(session, "#change-result", text: expected)
  end
end
