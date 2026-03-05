defmodule Cerberus.PhoenixTestShimTest do
  use ExUnit.Case, async: true
  use Cerberus.PhoenixTestShim

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  test "use macro imports shim helpers and Assertions alias", %{conn: conn} do
    conn
    |> visit("/search")
    |> Assertions.assert_has("h1", text: "Search")
    |> Assertions.refute_has("body", text: "Definitely Missing")
  end

  test "navigation and path assertions work with query_params alias", %{conn: conn} do
    conn
    |> visit("/search?sort=desc")
    |> assert_path("/search", query_params: %{sort: "desc"})
    |> refute_path("/search", query_params: %{sort: "asc"})
    |> then(fn session ->
      assert current_path(session) == "/search?sort=desc"
    end)
  end

  test "link click plus fill_in and submit flow", %{conn: conn} do
    conn
    |> visit("/search")
    |> click_link("Articles")
    |> assert_has("h1", text: "Articles")
    |> visit("/search")
    |> fill_in("Search term", with: "phoenix")
    |> submit("Run Search")
    |> assert_has("body", text: "Search query: phoenix")
  end

  test "select and choose flow", %{conn: conn} do
    conn
    |> visit("/controls")
    |> select("Race", option: "Dwarf")
    |> choose("Email Choice")
    |> submit("Save Controls")
    |> assert_has("body", text: "race: dwarf")
    |> assert_has("body", text: "contact: email")
  end

  test "check and uncheck flow", %{conn: conn} do
    conn
    |> visit("/checkbox-array")
    |> check("Two")
    |> uncheck("One")
    |> submit("Save Items")
    |> assert_has("body", text: "Selected Items: two")
  end

  test "TestHelpers.ignore_whitespace is exposed" do
    regex =
      TestHelpers.ignore_whitespace("""
      Name:
        Aragorn
      """)

    assert Regex.match?(regex, "Name:\nAragorn")
  end
end
