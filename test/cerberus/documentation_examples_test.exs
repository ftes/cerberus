defmodule Cerberus.DocumentationExamplesTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Cerberus.Browser

  alias Cerberus.TestSupport.SharedBrowserSession

  setup_all do
    {owner_pid, browser_session} = SharedBrowserSession.start!()

    on_exit(fn ->
      SharedBrowserSession.stop(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "quickstart counter flow from docs works across auto and browser (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/articles")
      |> assert_has(~l"Articles"e)
      |> click(~l"link:Counter"r)
      |> assert_has(~l"Count: 0"e)
    end

    test "form plus path flow from docs works across auto and browser (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> fill_in(~l"Search term"l, "Aragorn")
      |> submit(~l"button:Run Search"r)
      |> assert_path("/search/results", query: %{q: "Aragorn"})
      |> assert_has(~l"Search query: Aragorn"e)
    end

    test "scoped navigation flow from docs works across auto and browser (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/scoped")
      |> within(~l"#secondary-panel"c, fn scoped ->
        scoped
        |> assert_has(~l"Status: secondary"e)
        |> click(~l"link:Open"r)
      end)
      |> assert_path("/search")
    end

    test "multi-user and multi-tab flow from docs preserves isolation semantics (#{driver})", context do
      primary =
        unquote(driver)
        |> driver_session(context)
        |> visit("/session/user/alice")
        |> assert_has(~l"Session user: alice"e)

      _tab2 =
        primary
        |> open_tab()
        |> visit("/session/user")
        |> assert_has(~l"Session user: alice"e)

      unquote(driver)
      |> isolated_driver_session(context)
      |> visit("/session/user")
      |> assert_has(~l"Session user: unset"e)
      |> refute_has(~l"Session user: alice"e)
    end
  end

  test "async live assertion flow from docs works with timeout" do
    :phoenix
    |> session()
    |> visit("/live/async_page")
    |> assert_has(~l"Title loaded async"e, timeout: 500)
  end

  test "browser extension snippet from docs works", context do
    session =
      :browser
      |> driver_session(context)
      |> visit("/browser/extensions")
      |> type(~l"#keyboard-input"c, "hello")
      |> press(~l"#press-input"c, "Enter")

    assert_has(session, ~l"Press result: submitted"e)
  end

  test "browser evaluate_js callback snippet from docs works", context do
    session =
      :browser
      |> driver_session(context)
      |> visit("/articles")
      |> evaluate_js("document.body.dataset.cerberus = 'ready'", fn _result -> :ok end)

    assert_path(session, "/articles")
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
  defp isolated_driver_session(:browser, _context), do: session(:browser)
  defp isolated_driver_session(driver, context), do: driver_session(driver, context)
end
