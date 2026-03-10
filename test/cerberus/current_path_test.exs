defmodule Cerberus.CurrentPathTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.TestSupport.SharedBrowserSession

  setup_all do
    {owner_pid, browser_session} = SharedBrowserSession.start!()

    on_exit(fn ->
      SharedBrowserSession.stop(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "current_path is updated on live patch in live and browser drivers (#{driver})", context do
      session =
        unquote(driver)
        |> driver_session(context)
        |> visit("/live/redirects")

      assert_path(session, "/live/redirects")

      session = click(session, role(:link, name: "Patch link", exact: true))
      assert_path(session, "/live/redirects", query: %{details: "true", foo: "bar"})
    end

    test "current_path is updated on push navigation in live and browser drivers (#{driver})", context do
      session =
        unquote(driver)
        |> driver_session(context)
        |> visit("/live/redirects")

      assert_path(session, "/live/redirects")

      session = click(session, ~l"Button with push navigation"e)
      assert_path(session, "/live/counter", query: %{foo: "bar"})
    end

    test "query strings are preserved in current_path tracking across drivers (#{driver})", context do
      session =
        unquote(driver)
        |> driver_session(context)
        |> visit("/search")
        |> fill_in(~l"Search term"l, "phoenix")
        |> submit(~l"Run Search"e)

      assert_path(session, "/search/results", query: %{q: "phoenix"})
    end

    test "prefixed fixture paths keep prefix and query in current_path across drivers (#{driver})", context do
      session =
        unquote(driver)
        |> driver_session(context)
        |> visit("/phoenix_test/page/index?source=core")

      session
      |> assert_path("/phoenix_test/page/index", query: %{source: "core"})
      |> click(role(:link, name: "Page 2"))
      |> assert_path("/phoenix_test/page/page_2", query: %{foo: "bar"})
    end

    test "reload_page preserves current_path after live patch transitions (#{driver})", context do
      session =
        unquote(driver)
        |> driver_session(context)
        |> visit("/live/redirects")
        |> click(role(:link, name: "Patch link", exact: true))

      assert_path(session, "/live/redirects", query: %{details: "true", foo: "bar"})

      reloaded = reload_page(session)
      assert_path(reloaded, "/live/redirects", query: %{details: "true", foo: "bar"})
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
