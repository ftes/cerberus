defmodule Cerberus.ApiExamplesTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:phoenix, :browser] do
    test "static page text presence and absence use public API example flow (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/articles")
      |> assert_has(text("Articles"))
      |> assert_has(text("This is an articles index page"))
      |> refute_has(text("500 Internal Server Error"))
    end

    test "same counter click example runs in live and browser drivers (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/counter")
      |> click(role(:button, name: "Increment"))
      |> assert_has(text("Count: 1", exact: true))
    end

    test "failure messages include locator and options for reproducible debugging (#{driver})" do
      error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> session()
          |> visit("/articles")
          |> assert_has(text: "DOES NOT EXIST", exact: true)
        end

      assert error.message =~ "assert_has failed"
      assert error.message =~ ~s(locator: [text: "DOES NOT EXIST", exact: true])
      assert error.message =~ "opts:"
      assert error.message =~ "visible: true"
      assert error.message =~ ~r/timeout: (0|500)/
    end
  end
end
