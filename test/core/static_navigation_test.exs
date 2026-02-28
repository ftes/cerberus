defmodule Cerberus.CoreStaticNavigationTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag :static

  test "static driver supports link navigation into deterministic page state", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/articles")
      |> click(text: "Counter")
      |> assert_has(text: "Count: 0", exact: true)
    end)
  end

  test "static session auto-switches to live for dynamic button interactions", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/counter")
      |> click(text: "Increment")
      |> assert_has(text: "Count: 1", exact: true)
    end)
  end

  test "static redirects are deterministic and stay inside fixture routes", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/redirect/static")
      |> assert_has(text: "Articles")
      |> visit("/redirect/live")
      |> assert_has(text: "Count: 0", exact: true)
    end)
  end
end
