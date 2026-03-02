defmodule MigrationFixtureWeb.PtMultiUserTabTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_multi_user_tab", %{conn: conn} do
    conn
    |> visit("/session-counter")
    |> assert_session_count("0")
    |> click_link("Increment Session")
    |> assert_session_count("1")
  end

  defp assert_session_count(session, value) do
    expected = "Session Count: #{value}"

    PhoenixTest.Assertions.assert_has(session, "body", text: expected)
  end
end
