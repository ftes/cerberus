defmodule Cerberus.DataMethodClickBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  test "static click(button) submits data-method request" do
    session()
    |> visit("/phoenix_test/page/index")
    |> click(role(:button, name: "Data-method Delete"))
    |> assert_has(and_(css("h1"), text("Record deleted")))
  end

  test "live click(button) submits data-method request" do
    session()
    |> visit("/phoenix_test/live/index")
    |> click(role(:button, name: "Data-method Delete"))
    |> assert_has(and_(css("h1"), text("Record deleted")))
  end

  test "browser click(button) submits data-method request" do
    :browser
    |> session()
    |> visit("/phoenix_test/page/index")
    |> click(role(:button, name: "Data-method Delete"))
    |> assert_has(and_(css("h1"), text("Record deleted")))
  end

  test "click(button) raises a helpful error when data-method target is missing" do
    static_session = visit(session(), "/phoenix_test/page/index")

    assert_raise ExUnit.AssertionError, ~r/data-method element must define `data-to` or `href`/, fn ->
      click(static_session, role(:button, name: "Incomplete data-method Delete"))
    end
  end
end
