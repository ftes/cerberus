defmodule Cerberus.Compat.PhoenixTestShimBehaviorTest do
  use ExUnit.Case, async: true
  use Cerberus.PhoenixTestShim

  alias ExUnit.AssertionError

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

  test "value option matches against input value attributes", %{conn: conn} do
    conn
    |> visit("/phoenix_test/page/by_value")
    |> assert_has("input", value: "Frodo")
    |> refute_has("input", value: "not-frodo")
  end

  test "refute_has raises when value is present", %{conn: conn} do
    session = visit(conn, "/phoenix_test/page/by_value")

    error =
      assert_raise AssertionError, fn ->
        refute_has(session, "input", value: "Frodo")
      end

    assert Exception.message(error) =~ "Frodo"
    assert Exception.message(error) =~ "refute_has failed"
  end

  test "raises when both :text and :value options are provided", %{conn: conn} do
    session = visit(conn, "/phoenix_test/page/by_value")

    error =
      assert_raise ArgumentError, fn ->
        assert_has(session, "input", text: "some text", value: "some value")
      end

    assert Exception.message(error) =~ "Cannot provide both :text and :value"
  end

  test "raises clear error for text arg plus :text option", %{conn: conn} do
    session = visit(conn, "/search")

    assert_raise ArgumentError, ~r/Cannot specify `text` as the third argument/, fn ->
      assert_has(session, "h1", "Search", text: "Other text")
    end

    assert_raise ArgumentError, ~r/Cannot specify `text` as the third argument/, fn ->
      refute_has(session, "h1", "Search", text: "Other text")
    end
  end

  test "selector plus label assertion works for form controls in static and live pages", %{conn: conn} do
    for path <- ["/phoenix_test/page/index", "/phoenix_test/live/index"] do
      conn
      |> visit(path)
      |> assert_has("textarea[disabled]", label: "Disabled textaread")
      |> refute_has("textarea[disabled]", label: "Definitely Missing Label")
    end
  end

  test "option[selected] assertions follow selected form state after select", %{conn: conn} do
    conn
    |> visit("/controls")
    |> select("Race", option: "Dwarf")
    |> assert_has("select[name='race'] option[value='dwarf'][selected]")
    |> refute_has("select[name='race'] option[value='human'][selected]")
  end

  test "option[selected] assertions follow selected form state in live sessions", %{conn: conn} do
    conn
    |> visit("/phoenix_test/live/index")
    |> select("#pre-rendered-data-non-liveview-form select[name='select']", option: "Not selected")
    |> assert_has("select[name='select'] option[value='not_selected'][selected]")
  end
end
