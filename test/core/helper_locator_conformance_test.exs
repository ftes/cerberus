defmodule Cerberus.CoreHelperLocatorConformanceTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag :conformance

  @tag drivers: [:static, :browser]
  test "helper locators are consistent across static and browser for forms and navigation", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/search")
        |> fill_in(label("Search term"), "phoenix")
        |> submit(button("Run Search"))
        |> assert_has(text("Search query: phoenix"), exact: true)
        |> visit("/search")
        |> fill_in(role(:textbox, name: "Search term"), "elixir")
        |> submit(role(:button, name: "Run Search"))
        |> assert_has(text("Search query: elixir"), exact: true)
        |> visit("/articles")
        |> click(role(:link, name: "Counter"))
        |> assert_has(role(:button, name: "Increment"), exact: true)
        |> click(link("Articles"))
        |> assert_has(text("Articles"), exact: true)
      end
    )
  end

  @tag drivers: [:static, :browser]
  test "sigil modifiers are consistent across static and browser for role/css/exact flows", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/articles")
        |> click(~l"link:Counter"r)
        |> assert_has(~l"button:Increment"re)
        |> visit("/search")
        |> fill_in(~l"#search_q"c, "elixir")
        |> submit(~l"button[type='submit']"c)
        |> assert_has(~l"Search query: elixir"e)
      end
    )
  end

  @tag browser: true
  @tag drivers: [:live, :browser]
  test "duplicate live button labels are disambiguated for render_click conversion", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/selector-edge")
        |> click(button("Apply"))
        |> assert_has(text("Selected: primary"), exact: true)
        |> click(role(:button, name: "Apply"))
        |> assert_has(text("Selected: primary"), exact: true)
      end
    )
  end

  @tag browser: true
  @tag drivers: [:live, :browser]
  test "css sigil selector disambiguates duplicate live button labels", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/selector-edge")
        |> click(~l"#secondary-actions button"c)
        |> assert_has(text("Selected: secondary"), exact: true)
      end
    )
  end

  @tag browser: true
  @tag drivers: [:live, :browser]
  test "role link helper navigates from live route consistently", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/selector-edge")
        |> click(role(:link, name: "Articles"))
        |> assert_has(text("Articles"), exact: true)
      end
    )
  end

  @tag drivers: [:static, :browser]
  test "testid helper reports explicit unsupported behavior across drivers", context do
    results =
      Harness.run(context, fn session ->
        session
        |> visit("/articles")
        |> assert_has(testid("articles-title"))
      end)

    assert results != []
    assert Enum.all?(results, &(&1.status == :error))

    Enum.each(results, fn result ->
      assert result.message =~ "testid locators are not yet supported"
    end)
  end
end
