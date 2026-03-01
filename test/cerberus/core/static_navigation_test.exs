defmodule Cerberus.CoreStaticNavigationTest do
  use ExUnit.Case, async: true

  import Cerberus

  test "static driver supports link navigation into deterministic page state" do
    :phoenix
    |> session()
    |> visit("/articles")
    |> click(text: "Counter")
    |> assert_has(text: "Count: 0", exact: true)
  end

  test "static session auto-switches to live for dynamic button interactions" do
    :phoenix
    |> session()
    |> visit("/live/counter")
    |> click(text: "Increment")
    |> assert_has(text: "Count: 1", exact: true)
  end

  test "static redirects are deterministic and stay inside fixture routes" do
    :phoenix
    |> session()
    |> visit("/redirect/static")
    |> assert_has(text: "Articles")
    |> visit("/redirect/live")
    |> assert_has(text: "Count: 0", exact: true)
  end
end
