defmodule MigrationFixtureWeb.PtScopeNestedTest do
  use MigrationFixtureWeb.ConnCase, async: true

  import PhoenixTest

  test "pt_scope_nested", %{conn: conn} do
    conn
    |> visit("/")
    |> click_link("Counter")
    |> within("div", fn scoped ->
      assert_count(scoped, "0")
    end)
  end

  defp assert_count(session, expected_text) do
    PhoenixTest.Assertions.assert_has(session, "#count", text: expected_text)
  end
end
