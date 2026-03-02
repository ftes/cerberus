defmodule MigrationFixtureWeb.PtChooseTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_choose", %{conn: conn} do
    conn
    |> visit("/choose")
    |> choose_contact("Phone")
    |> submit_choice()
    |> assert_contact_choice("phone")
  end

  defp choose_contact(session, label) do
    choose(session, label)
  end

  defp assert_contact_choice(session, expected_value) do
    expected = "Contact via: #{expected_value}"

    PhoenixTest.Assertions.assert_has(session, "body", text: expected)
  end

  defp submit_choice(session) do
    click_button(session, "Apply Choice")
  end
end
