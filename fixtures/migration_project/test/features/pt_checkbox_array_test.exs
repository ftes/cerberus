defmodule MigrationFixtureWeb.PtCheckboxArrayTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_checkbox_array", %{conn: conn} do
    checked =
      conn
      |> visit("/checkbox")
      |> check("Two")
      |> submit_items()

    assert_selected_items(checked, "one,two")

    unchecked =
      conn
      |> visit("/checkbox")
      |> check("Two")
      |> uncheck("Two")
      |> submit_items()

    assert_selected_items(unchecked, "one")
  end

  defp assert_selected_items(session, items) do
    expected = "Selected Items: #{items}"

    PhoenixTest.Assertions.assert_has(session, "body", text: expected)
  end

  defp submit_items(session) do
    click_button(session, "Save Items")
  end
end
