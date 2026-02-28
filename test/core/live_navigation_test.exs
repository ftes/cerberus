defmodule Cerberus.CoreLiveNavigationTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag drivers: [:live, :browser]

  test "dynamic counter updates are consistent between live and browser drivers", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/counter")
      |> click(text: "Increment")
      |> assert_has(text: "Count: 1", exact: true)
    end)
  end

  test "live redirects are deterministic in live and browser drivers", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/redirects")
      |> click(text: "Redirect to Articles")
      |> assert_has(text: "Articles")
      |> visit("/live/redirects")
      |> click(text: "Redirect to Counter")
      |> assert_has(text: "Count: 0", exact: true)
    end)
  end
end
