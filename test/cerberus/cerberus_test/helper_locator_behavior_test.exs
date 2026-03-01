defmodule CerberusTest.HelperLocatorBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:phoenix, :browser] do
    test "helper locators are consistent across static and browser for forms and navigation (#{driver})" do
      unquote(driver)
      |> session()
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

    test "sigil modifiers are consistent across static and browser for role/css/exact flows (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/articles")
      |> click(~l"link:Counter"r)
      |> assert_has(~l"button:Increment"re)
      |> visit("/search")
      |> fill_in(~l"#search_q"c, "elixir")
      |> submit(~l"button[type='submit']"c)
      |> assert_has(~l"Search query: elixir"e)
    end

    test "duplicate live button labels are disambiguated for render_click conversion (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/selector-edge")
      |> click(button("Apply"))
      |> assert_has(text("Selected: primary", exact: true))
      |> click(role(:button, name: "Apply"))
      |> assert_has(text("Selected: primary", exact: true))
    end

    test "css sigil selector disambiguates duplicate live button labels (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/selector-edge")
      |> click(~l"#secondary-actions button"c)
      |> assert_has(text("Selected: secondary", exact: true))
    end

    test "click_button handles multiline data-confirm attributes (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/selector-edge")
      |> click_button(button("Create", exact: true))
      |> assert_has(text("Selected: confirmed", exact: true))
    end

    test "role link helper navigates from live route consistently (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/selector-edge")
      |> click(role(:link, name: "Articles"))
      |> assert_has(text("Articles", exact: true))
    end

    test "testid helper works across drivers for assertions and form actions (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/articles")
      |> assert_has(testid("articles-title"))
      |> visit("/search")
      |> fill_in(testid("search-input"), "gandalf")
      |> submit(testid("search-submit"))
      |> assert_has(text("Search query: gandalf", exact: true))
    end

    test "testid helper supports click targets on live routes (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/articles")
      |> click(testid("articles-counter-link"))
      |> click(testid("counter-increment-button"))
      |> assert_has(text("Count: 1", exact: true))
    end

    test "testid click disambiguates duplicate live button text without relying on text fallback (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/selector-edge")
      |> click(testid("apply-secondary"))
      |> assert_has(text("Selected: secondary", exact: true))
    end

    test "placeholder/title/alt helpers behave consistently in static and browser (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/articles")
      |> assert_has(title("Articles heading", exact: true))
      |> assert_has(alt("Articles hero image", exact: true))
      |> visit("/search")
      |> assert_has(testid("search-title"))
      |> fill_in(placeholder("Search by term"), "boromir")
      |> submit(title("Run search button", exact: true))
      |> assert_has(text("Search query: boromir", exact: true))
    end

    test "placeholder/title/testid helpers behave consistently in live and browser (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/form-change")
      |> assert_has(title("Live name input", exact: true))
      |> fill_in(placeholder("Live name"), "Eowyn")
      |> assert_has(testid("live-change-name"))
      |> assert_has(text("name: Eowyn", exact: true))
    end
  end
end
