defmodule Cerberus.InputSubmitButtonBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  test "click(button/1) matches input type=submit in browser sessions" do
    :browser
    |> session()
    |> visit("/phoenix_test/playwright/page/index")
    |> within(css("#same-labels"), fn session ->
      click(session, button("Save form", exact: true))
    end)
    |> assert_has("#form-data" |> css() |> text("button: Save form", exact: false))
  end

  test "submit(button/1) matches input type=submit in static sessions" do
    session()
    |> visit("/phoenix_test/playwright/page/index")
    |> submit(button("Save form", exact: true))
    |> assert_has("#form-data" |> css() |> text("button: Save form", exact: false))
  end
end
