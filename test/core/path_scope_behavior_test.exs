defmodule Cerberus.CorePathScopeBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag :conformance

  @tag drivers: [:static, :browser]
  test "within scopes static operations and assertions across static and browser", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/scoped")
        |> within("#secondary-panel", fn scoped ->
          scoped
          |> assert_has(text("Secondary Panel", exact: true))
          |> assert_has(text("Status: secondary", exact: true))
          |> refute_has(text("Status: primary", exact: true))
          |> click(link("Open"))
        end)
        |> assert_path("/search")
        |> assert_has(text("Search", exact: true))
      end
    )
  end

  @tag drivers: [:static, :browser]
  test "path assertions with query options are consistent in static and browser drivers", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/search")
        |> fill_in(label("Search term"), "phoenix")
        |> submit(button("Run Search"))
        |> assert_path("/search/results", query: %{q: "phoenix"})
        |> refute_path("/search/results", query: %{q: "elixir"})
      end
    )
  end

  @tag browser: true
  @tag drivers: [:live, :browser]
  test "within scopes live duplicate button clicks consistently in live and browser", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/selector-edge")
        |> within("#secondary-actions", fn scoped ->
          click(scoped, button("Apply"))
        end)
        |> within("#selected-result", fn scoped ->
          scoped
          |> assert_has(text("Selected: secondary", exact: true))
          |> refute_has(text("Selected: primary", exact: true))
        end)
      end
    )
  end

  @tag browser: true
  @tag drivers: [:live, :browser]
  test "path assertions track live patch query transitions across drivers", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/redirects")
        |> click(button("Patch link"))
        |> assert_path("/live/redirects", query: [details: "true", foo: "bar"])
        |> assert_path("/live/redirects?details=true&foo=bar")
        |> refute_path("/live/counter")
      end
    )
  end
end
