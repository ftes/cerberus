defmodule Cerberus.CoreHelperLocatorBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @tag :static
  @tag :browser
  test "helper locators are consistent across static and browser for forms and navigation", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/search")
        |> fill_in(label("Search term"), "phoenix")
        |> submit(button("Run Search"))
        |> assert_has(text("Search query: phoenix", exact: true))
        |> visit("/search")
        |> fill_in(role(:textbox, name: "Search term"), "elixir")
        |> submit(role(:button, name: "Run Search"))
        |> assert_has(text("Search query: elixir", exact: true))
        |> visit("/articles")
        |> click(role(:link, name: "Counter"))
        |> assert_has(role(:button, name: "Increment", exact: true))
        |> click(link("Articles"))
        |> assert_has(text("Articles", exact: true))
      end
    )
  end

  @tag :static
  @tag :browser
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

  @tag :live
  @tag :browser
  test "duplicate live button labels are disambiguated for render_click conversion", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/selector-edge")
        |> click(button("Apply"))
        |> assert_has(text("Selected: primary", exact: true))
        |> click(role(:button, name: "Apply"))
        |> assert_has(text("Selected: primary", exact: true))
      end
    )
  end

  @tag :live
  @tag :browser
  test "css sigil selector disambiguates duplicate live button labels", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/selector-edge")
        |> click(~l"#secondary-actions button"c)
        |> assert_has(text("Selected: secondary", exact: true))
      end
    )
  end

  @tag :live
  @tag :browser
  test "click_button handles multiline data-confirm attributes", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/selector-edge")
        |> click_button(button("Create", exact: true))
        |> assert_has(text("Selected: confirmed", exact: true))
      end
    )
  end

  @tag :live
  @tag :browser
  test "role link helper navigates from live route consistently", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/selector-edge")
        |> click(role(:link, name: "Articles"))
        |> assert_has(text("Articles", exact: true))
      end
    )
  end

  @tag :static
  @tag :browser
  test "testid helper works across drivers for assertions and form actions", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/articles")
        |> assert_has(testid("articles-title"))
        |> visit("/search")
        |> fill_in(testid("search-input"), "gandalf")
        |> submit(testid("search-submit"))
        |> assert_has(text("Search query: gandalf", exact: true))
      end
    )
  end

  @tag :static
  @tag :browser
  test "placeholder/title/alt helpers behave consistently in static and browser", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/articles")
        |> assert_has(title("Articles heading", exact: true))
        |> assert_has(alt("Articles hero image", exact: true))
        |> visit("/search")
        |> assert_has(testid("search-title"))
        |> fill_in(placeholder("Search by term"), "boromir")
        |> submit(title("Run search button", exact: true))
        |> assert_has(text("Search query: boromir", exact: true))
      end
    )
  end

  @tag :live
  @tag :browser
  test "placeholder/title/testid helpers behave consistently in live and browser", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/form-change")
        |> assert_has(title("Live name input", exact: true))
        |> fill_in(placeholder("Live name"), "Eowyn")
        |> assert_has(testid("live-change-name"))
        |> assert_has(text("name: Eowyn", exact: true))
      end
    )
  end
end
