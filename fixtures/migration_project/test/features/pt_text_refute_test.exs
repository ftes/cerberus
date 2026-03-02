defmodule MigrationFixtureWeb.PtTextRefuteTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_text_refute", %{conn: conn} do
    conn
    |> visit("/")
    |> refute_missing_text("Does not exist")
  end

  defp refute_missing_text(session, expected_text) do
    PhoenixTest.Assertions.refute_has(session, "body", text: expected_text)
  end
end
