defmodule Cerberus.CoreCurrentPathTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:phoenix, :browser] do
    test "current_path is updated on live patch in live and browser drivers (#{driver})" do
      session =
        unquote(driver)
        |> session()
        |> visit("/live/redirects")

      assert session.current_path == "/live/redirects"

      session = click_button(session, text: "Patch link")
      assert session.current_path == "/live/redirects?details=true&foo=bar"
    end

    test "current_path is updated on push navigation in live and browser drivers (#{driver})" do
      session =
        unquote(driver)
        |> session()
        |> visit("/live/redirects")

      assert session.current_path == "/live/redirects"

      session = click_button(session, text: "Button with push navigation")
      assert session.current_path == "/live/counter?foo=bar"
    end

    test "query strings are preserved in current_path tracking across drivers (#{driver})" do
      session =
        unquote(driver)
        |> session()
        |> visit("/search")
        |> fill_in("Search term", "phoenix")
        |> submit(text: "Run Search")

      assert session.current_path == "/search/results?q=phoenix"
    end

    test "reload_page preserves current_path after live patch transitions (#{driver})" do
      session =
        unquote(driver)
        |> session()
        |> visit("/live/redirects")
        |> click_button(text: "Patch link")

      assert session.current_path == "/live/redirects?details=true&foo=bar"

      reloaded = reload_page(session)
      assert reloaded.current_path == "/live/redirects?details=true&foo=bar"
    end
  end
end
