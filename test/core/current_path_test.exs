defmodule Cerberus.CoreCurrentPathTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag :live
  @moduletag :browser

  test "current_path is updated on live patch in live and browser drivers", context do
    Harness.run!(
      context,
      fn session ->
        session = visit(session, "/live/redirects")
        assert session.current_path == "/live/redirects"

        session = click_button(session, text: "Patch link")
        assert session.current_path == "/live/redirects?details=true&foo=bar"
        session
      end
    )
  end

  test "current_path is updated on push navigation in live and browser drivers", context do
    Harness.run!(
      context,
      fn session ->
        session = visit(session, "/live/redirects")
        assert session.current_path == "/live/redirects"

        session = click_button(session, text: "Button with push navigation")
        assert session.current_path == "/live/counter?foo=bar"
        session
      end
    )
  end

  @tag :static
  @tag :browser
  test "query strings are preserved in current_path tracking across drivers", context do
    Harness.run!(
      context,
      fn session ->
        session =
          session
          |> visit("/search")
          |> fill_in("Search term", "phoenix")
          |> submit(text: "Run Search")

        assert session.current_path == "/search/results?q=phoenix"
        session
      end
    )
  end

  test "reload_page preserves current_path after live patch transitions", context do
    Harness.run!(
      context,
      fn session ->
        session =
          session
          |> visit("/live/redirects")
          |> click_button(text: "Patch link")

        assert session.current_path == "/live/redirects?details=true&foo=bar"

        reloaded = reload_page(session)
        assert reloaded.current_path == "/live/redirects?details=true&foo=bar"
        reloaded
      end
    )
  end
end
