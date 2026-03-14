defmodule Cerberus.CurrentPathTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Driver.Live
  alias Cerberus.Phoenix.LiveViewClient
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

    test "current_path tracks live phx-change push_patch query updates (#{driver})", context do
      session =
        unquote(driver)
        |> driver_session(context)
        |> visit("/phoenix_test/playwright/live/index")
        |> fill_in(~l"Patch query"l, "SELECT current_timestamp")

      assert_path(session, "/phoenix_test/playwright/live/index", query: %{sql: "SELECT current_timestamp"})
    end

    test "current_path tracks live select-driven push_patch updates (#{driver})", context do
      session =
        unquote(driver)
        |> driver_session(context)
        |> visit("/phoenix_test/playwright/live/index?unit=alpha&we_date=2023-04-23")
        |> select(~l"Patch unit"l, text("Beta", exact: true))

      assert_path(session, "/phoenix_test/playwright/live/index", query: %{unit: "beta", we_date: "2023-04-23"})
    end
  end

  test "live view client emits patch navigation for phx-change input updates", context do
    session =
      :phoenix
      |> driver_session(context)
      |> visit("/phoenix_test/playwright/live/index")

    assert %Live{} = session

    rendered =
      session.view
      |> LiveViewClient.form("#patch-query-form", %{"patch_query" => "SELECT current_timestamp"})
      |> LiveViewClient.render_change(%{"patch_query" => "SELECT current_timestamp"})

    assert is_binary(rendered)

    assert {:patch, %{to: "/phoenix_test/playwright/live/index?sql=SELECT+current_timestamp"}} =
             LiveViewClient.receive_navigation(session.view, 500)
  end

  test "live view client emits patch navigation for phx-change select updates", context do
    session =
      :phoenix
      |> driver_session(context)
      |> visit("/phoenix_test/playwright/live/index?unit=alpha&we_date=2023-04-23")

    assert %Live{} = session

    rendered =
      session.view
      |> LiveViewClient.form("#patch-unit-form", %{"patch_unit" => "beta"})
      |> LiveViewClient.render_change(%{"patch_unit" => "beta"})

    assert is_binary(rendered)

    assert {:patch, %{to: "/phoenix_test/playwright/live/index?unit=beta&we_date=2023-04-23"}} =
             LiveViewClient.receive_navigation(session.view, 500)
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
