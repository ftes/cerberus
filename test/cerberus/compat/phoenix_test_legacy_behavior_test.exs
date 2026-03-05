defmodule Cerberus.Compat.PhoenixTestLegacyBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus.TestSupport.PhoenixTest.Legacy

  alias ExUnit.AssertionError

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  test "live title assertions use LiveView page title", %{conn: conn} do
    conn
    |> visit("/live/index")
    |> assert_has("title")
    |> assert_has("title", text: "PhoenixTest is the best!")
    |> refute_has("title", text: "Not the title")
  end

  test "live title mismatch raises helpful message", %{conn: conn} do
    error =
      assert_raise AssertionError, fn ->
        conn
        |> visit("/live/index")
        |> assert_has("title", text: "Not the title")
      end

    assert Exception.message(error) =~ "Expected title to be"
    assert Exception.message(error) =~ "Not the title"
  end

  test "value option matches input value attributes", %{conn: conn} do
    conn
    |> visit("/page/by_value")
    |> assert_has("input", value: "Frodo")
    |> refute_has("input", value: "not-frodo")
  end

  test "refute_has raises when input value is present", %{conn: conn} do
    session = visit(conn, "/page/by_value")

    error =
      assert_raise AssertionError, fn ->
        refute_has(session, "input", value: "Frodo")
      end

    assert Exception.message(error) =~ "Frodo"
  end

  test "at option narrows CSS selector positionally", %{conn: conn} do
    conn
    |> visit("/page/index")
    |> assert_has("#multiple-items li", at: 2, text: "Legolas")
    |> refute_has("#multiple-items li", at: 2, text: "Aragorn")
  end

  test "legacy visit prefixes routes and current_path strips prefix", %{conn: conn} do
    session = visit(conn, "/page/index?source=compat")

    assert current_path(session) == "/page/index?source=compat"

    session
    |> assert_path("/page/index", query: %{source: "compat"})
    |> refute_path("/page/page_2")
  end

  test "label and value assertion compatibility path works", %{conn: conn} do
    conn
    |> visit("/page/by_value")
    |> assert_has("input", value: "Frodo", label: "Hobbit")
    |> refute_has("input", value: "Frodo", label: "Elf")
  end

  test "label and value mismatch errors remain helpful", %{conn: conn} do
    session = visit(conn, "/page/by_value")

    assert_raise AssertionError, ~r/Could not find .*value "Frodo".*label "Elf"/, fn ->
      assert_has(session, "input", value: "Frodo", label: "Elf")
    end

    assert_raise AssertionError, ~r/Expected not to find .*value "Frodo".*label "Hobbit"/, fn ->
      refute_has(session, "input", value: "Frodo", label: "Hobbit")
    end
  end
end
