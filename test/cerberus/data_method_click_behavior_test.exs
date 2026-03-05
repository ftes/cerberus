defmodule Cerberus.DataMethodClickBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  test "static click(button) submits data-method request" do
    session()
    |> visit("/phoenix_test/page/index")
    |> click(button("Data-method Delete"))
    |> assert_has("h1" |> css() |> text("Record deleted"))
  end

  test "live click(button) submits data-method request" do
    session()
    |> visit("/phoenix_test/live/index")
    |> click(button("Data-method Delete"))
    |> assert_has("h1" |> css() |> text("Record deleted"))
  end

  test "browser click(button) submits data-method request" do
    :browser
    |> session()
    |> visit("/phoenix_test/page/index")
    |> click(button("Data-method Delete"))
    |> assert_has("h1" |> css() |> text("Record deleted"))
  end

  test "click(button) raises a helpful error when data-method target is missing" do
    static_session = visit(session(), "/phoenix_test/page/index")

    assert_raise ExUnit.AssertionError, ~r/data-method element must define `data-to` or `href`/, fn ->
      click(static_session, button("Incomplete data-method Delete"))
    end
  end
end
