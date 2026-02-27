defmodule Cerberus.CoreAutoModeTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag :conformance
  @moduletag drivers: [:auto]

  test "auto mode starts static and switches to live when navigating to live routes", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/articles")
      |> assert_has([text: "Articles"], exact: true)
      |> visit("/live/counter")
      |> click_button(text: "Increment")
      |> assert_has([text: "Count: 1"], exact: true)
    end)
  end

  test "auto mode starts live and switches to static on non-live navigation", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/counter")
      |> click_link(text: "Articles")
      |> assert_has([text: "Articles"], exact: true)
    end)
  end
end
