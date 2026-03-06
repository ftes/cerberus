defmodule Cerberus.LiveSelectRegressionTest do
  use ExUnit.Case, async: true

  import Cerberus

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  test "live multi-select preserves previous picks across repeated calls", %{conn: conn} do
    conn
    |> session()
    |> visit("/phoenix_test/live/index")
    |> select(label("Race 2"), option: text("Elf"))
    |> select(label("Race 2"), option: text("Dwarf"))
    |> click(role(:button, name: "Save Full Form"))
    |> assert_has("#form-data" |> css() |> text("[elf, dwarf]", exact: false))
  end

  test "browser live multi-select preserves previous picks across repeated calls" do
    :browser
    |> session()
    |> visit("/phoenix_test/live/index")
    |> select(label("Race 2"), option: text("Elf"))
    |> select(label("Race 2"), option: text("Dwarf"))
    |> click(role(:button, name: "Save Full Form"))
    |> assert_has("#form-data" |> css() |> text("[elf, dwarf]", exact: false))
  end

  test "live select outside forms dispatches option phx-click events", %{conn: conn} do
    conn
    |> session()
    |> visit("/phoenix_test/live/index")
    |> within(css("#not-a-form"), fn scoped ->
      select(scoped, label("Choose a pet:"), option: [text("Dog"), text("Cat")])
    end)
    |> assert_has("#form-data" |> css() |> text("selected: [dog, cat]"))
  end

  test "browser live select outside forms dispatches option phx-click events" do
    :browser
    |> session()
    |> visit("/phoenix_test/live/index")
    |> within(css("#not-a-form"), fn scoped ->
      select(scoped, label("Choose a pet:"), option: [text("Dog"), text("Cat")])
    end)
    |> assert_has("#form-data" |> css() |> text("selected: [dog, cat]"))
  end

  test "live select outside forms without option phx-click raises a contract error", %{conn: conn} do
    live_session =
      conn
      |> session()
      |> visit("/phoenix_test/live/index")

    assert_raise ArgumentError,
                 ~r/to have a valid `phx-click` attribute on options or to belong to a `form`/,
                 fn ->
                   select(live_session, label("Invalid Select Option"), option: text("Dog"))
                 end
  end

  test "live link click raises ambiguity error when duplicate text matches", %{conn: conn} do
    assert_raise ArgumentError, ~r/2 of them matched the text filter/, fn ->
      conn
      |> session()
      |> visit("/phoenix_test/live/index")
      |> click(role(:link, name: "Multiple links", exact: false))
    end
  end
end
