defmodule Cerberus.CoreLiveNavigationTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:phoenix, :browser] do
    test "dynamic counter updates are consistent between live and browser drivers (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/counter")
      |> click(text: "Increment")
      |> assert_has(text: "Count: 1", exact: true)
    end

    test "live redirects are deterministic in live and browser drivers (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/redirects")
      |> click(text: "Redirect to Articles")
      |> assert_has(text: "Articles")
      |> visit("/live/redirects")
      |> click(text: "Redirect to Counter")
      |> assert_has(text: "Count: 0", exact: true)
    end
  end
end
