defmodule CerberusTest.CrossDriverTextTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:phoenix, :browser] do
    test "text assertions behave consistently for static pages in static and browser drivers (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/articles")
      |> assert_has(text: "Articles")
      |> assert_has(~r/articles index/i)
      |> refute_has(text: "500 Internal Server Error")
      |> assert_has([text: "Hidden helper text"], visible: false)
    end
  end
end
