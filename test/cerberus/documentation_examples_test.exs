defmodule Cerberus.DocumentationExamplesTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Cerberus.Browser

  for driver <- [:phoenix, :browser] do
    test "quickstart counter flow from docs works across auto and browser (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/articles")
      |> assert_has(text("Articles", exact: true))
      |> click(link("Counter"))
      |> assert_has(text("Count: 0", exact: true))
    end

    test "form plus path flow from docs works across auto and browser (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/search")
      |> fill_in(label("Search term"), "Aragorn")
      |> submit(button("Run Search"))
      |> assert_path("/search/results", query: %{q: "Aragorn"})
      |> assert_has(text("Search query: Aragorn", exact: true))
    end

    test "scoped navigation flow from docs works across auto and browser (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/scoped")
      |> within("#secondary-panel", fn scoped ->
        scoped
        |> assert_has(text("Status: secondary", exact: true))
        |> click(link("Open"))
      end)
      |> assert_path("/search")
    end

    test "multi-user and multi-tab flow from docs preserves isolation semantics (#{driver})" do
      primary =
        unquote(driver)
        |> session()
        |> visit("/session/user/alice")
        |> assert_has(text("Session user: alice", exact: true))

      _tab2 =
        primary
        |> open_tab()
        |> visit("/session/user")
        |> assert_has(text("Session user: alice", exact: true))

      primary
      |> open_user()
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

  test "browser extension snippet from docs works" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")
      |> type("hello", selector: "#keyboard-input")
      |> press("Enter", selector: "#press-input")
      |> with_dialog(fn dialog_session ->
        click(dialog_session, button("Open Confirm Dialog"))
      end)

    session
    |> assert_has(text("Press result: submitted", exact: true))
    |> assert_has(text("Dialog result: cancelled", exact: true))
  end
end
