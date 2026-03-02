defmodule MigrationFixtureWeb.PtSelectTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_select", %{conn: conn} do
    conn
    |> visit("/select")
    |> select_role("Wizard")
    |> submit_selection()
    |> assert_selected_role("wizard")
  end

  defp select_role(session, option_text) do
    select(session, "Role", option: option_text)
  end

  defp assert_selected_role(session, expected_value) do
    expected = "Selected role: #{expected_value}"

    PhoenixTest.Assertions.assert_has(session, "body", text: expected)
  end

  defp submit_selection(session) do
    click_button(session, "Apply Selection")
  end
end
