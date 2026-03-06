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
      |> assert_has(text("Articles", exact: true))
      |> click(role(:link, name: "Counter"))
      |> assert_has(text("Count: 0", exact: true))
    end

    test "form plus path flow from docs works across auto and browser (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> fill_in(label("Search term"), "Aragorn")
      |> submit(role(:button, name: "Run Search"))
      |> assert_path("/search/results", query: %{q: "Aragorn"})
      |> assert_has(text("Search query: Aragorn", exact: true))
    end

    test "scoped navigation flow from docs works across auto and browser (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/scoped")
      |> within(css("#secondary-panel"), fn scoped ->
        scoped
        |> assert_has(text("Status: secondary", exact: true))
        |> click(role(:link, name: "Open"))
      end)
      |> assert_path("/search")
    end

    test "multi-user and multi-tab flow from docs preserves isolation semantics (#{driver})", context do
      primary =
        unquote(driver)
        |> driver_session(context)
        |> visit("/session/user/alice")
        |> assert_has(text("Session user: alice", exact: true))

      _tab2 =
        primary
        |> open_tab()
        |> visit("/session/user")
        |> assert_has(text("Session user: alice", exact: true))

      unquote(driver)
      |> isolated_driver_session(context)
      |> visit("/session/user")
      |> assert_has(text("Session user: unset", exact: true))
      |> refute_has(text("Session user: alice", exact: true))
    end
  end

  test "async live assertion flow from docs works with timeout" do
    :phoenix
    |> session()
    |> visit("/live/async_page")
    |> assert_has(text("Title loaded async"), timeout: 500)
  end

  test "browser extension snippet from docs works", context do
    session =
      :browser
      |> driver_session(context)
      |> visit("/browser/extensions")
      |> type("hello", selector: "#keyboard-input")
      |> press("Enter", selector: "#press-input")

    evaluate_js(session, "setTimeout(() => document.getElementById('confirm-dialog')?.click(), 10)", fn _ ->
      :ok
    end)

    session = assert_dialog(session, text("Delete item?", exact: true))

    session
    |> assert_has(text("Press result: submitted", exact: true))
    |> assert_has(text("Dialog result: confirmed", exact: true))
  end

  @tag :tmp_dir
  test "browser prompt snippet from docs works with callback chaining", %{tmp_dir: tmp_dir} = context do
    screenshot_path = Path.join(tmp_dir, "prompt-snippet.png")

    session =
      :browser
      |> driver_session(context)
      |> visit("/live/counter")
      |> evaluate_js("prompt('Hey!')", fn _result -> :ok end)
      |> screenshot(path: screenshot_path)

    assert session.current_path == "/live/counter"
    assert File.exists?(screenshot_path)
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
  defp isolated_driver_session(:browser, _context), do: session(:browser)
  defp isolated_driver_session(driver, context), do: driver_session(driver, context)
end
