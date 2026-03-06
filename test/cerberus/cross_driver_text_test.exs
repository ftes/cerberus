defmodule Cerberus.CrossDriverTextTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:phoenix, :browser] do
    test "text assertions behave consistently for static pages in static and browser drivers (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/articles")
      |> assert_has(~l"Articles"e)
      |> assert_has(text(~r/articles index/i))
      |> refute_has(~l"500 Internal Server Error"e)
      |> assert_has(~l"Hidden helper text"e, visible: false)
    end

    test "assert_has failure includes candidate hints (#{driver})" do
      error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> session()
          |> visit("/articles")
          |> assert_has(~l"Definitely Missing Text"e)
        end

      assert error.message =~ "possible candidates:"
      assert error.message =~ "Articles"
    end
  end
end
