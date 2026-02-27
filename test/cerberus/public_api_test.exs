defmodule Cerberus.PublicApiTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.InvalidLocatorError
  alias ExUnit.AssertionError

  test "session constructor returns per-driver structs for non-browser drivers" do
    assert %StaticSession{} = session(:static)
    assert %LiveSession{} = session(:live)
    assert %StaticSession{} = session(:auto)
  end

  test "open_user/open_tab/switch_tab API works for non-browser sessions" do
    primary =
      :static
      |> session()
      |> visit("/session/user/alice")
      |> assert_has(text("Session user: alice"), exact: true)

    tab =
      primary
      |> open_tab()
      |> visit("/session/user")
      |> assert_has(text("Session user: alice"), exact: true)

    isolated_user =
      primary
      |> open_user()
      |> visit("/session/user")
      |> assert_has(text("Session user: unset"), exact: true)

    switched = switch_tab(tab, primary)
    assert switched.current_path == "/session/user"

    closed = close_tab(tab)
    assert closed.current_path == "/session/user"
    assert isolated_user.current_path == "/session/user"
  end

  @tag browser: true
  test "session constructor returns a browser session" do
    assert %BrowserSession{} = session(:browser)
  end

  @tag browser: true
  test "switch_tab rejects mixed browser and non-browser sessions" do
    browser_tab =
      :browser
      |> session()
      |> visit("/articles")

    static_tab =
      :static
      |> session()
      |> visit("/articles")

    assert_raise ArgumentError, ~r/cannot switch browser tab to a non-browser session/, fn ->
      switch_tab(browser_tab, static_tab)
    end
  end

  test "assert_has with unsupported locator raises InvalidLocatorError" do
    assert_raise InvalidLocatorError, fn ->
      :static
      |> session()
      |> visit("/articles")
      |> assert_has(foo: "bar")
    end
  end

  test "assert_has accepts text sigil locator" do
    assert is_struct(
             :static
             |> session()
             |> visit("/articles")
             |> assert_has(~l"Articles")
           )
  end

  test "sigil modifiers support role and css locator flows" do
    session =
      :static
      |> session()
      |> visit("/articles")
      |> click(~l"link:Counter"r)
      |> assert_has(~l"button:Increment"re)
      |> visit("/search")
      |> fill_in(~l"#search_q"c, "phoenix")
      |> submit(~l"button[type='submit']"c)
      |> assert_has(~l"Search query: phoenix"e)

    assert session.current_path == "/search/results?q=phoenix"
  end

  test "label locators are explicit to fill_in and are rejected for click/assert" do
    assert_raise InvalidLocatorError, ~r/label locators target form-field lookup/, fn ->
      :static
      |> session()
      |> visit("/search")
      |> click(label("Search term"))
    end

    assert_raise InvalidLocatorError, ~r/label locators target form-field lookup/, fn ->
      :static
      |> session()
      |> visit("/search")
      |> assert_has(label("Search term"))
    end
  end

  test "helper locators work with click/assert/fill_in flows" do
    session =
      :static
      |> session()
      |> visit("/articles")
      |> click(link("Counter"))
      |> assert_has(role(:button, name: "Increment"))
      |> click(button("Increment"))
      |> assert_has(text("Count: 1"))

    assert session.current_path == "/live/counter"

    assert is_struct(
             :static
             |> session()
             |> visit("/search")
             |> fill_in(label("Search term"), "phoenix")
           )
  end

  test "testid helper is explicit about unsupported operations in this slice" do
    assert_raise InvalidLocatorError, ~r/testid locators are not yet supported/, fn ->
      :static
      |> session()
      |> visit("/articles")
      |> assert_has(testid("articles-title"))
    end
  end

  test "unsupported driver is rejected" do
    assert_raise ArgumentError, ~r/unsupported driver/, fn ->
      session(:unknown)
    end
  end

  test "fill_in accepts positional value argument" do
    assert is_struct(
             :static
             |> session()
             |> visit("/search")
             |> fill_in([text: "Search term"], "phoenix")
           )
  end

  test "invalid keyword options are rejected via NimbleOptions" do
    assert_raise ArgumentError, ~r/invalid options/, fn ->
      :static
      |> session()
      |> visit("/articles")
      |> click([text: "Articles"], kind: :nope)
    end
  end

  test "assert_has timeout option must be non-negative integer" do
    assert_raise ArgumentError, ~r/invalid options/, fn ->
      :static
      |> session()
      |> visit("/articles")
      |> assert_has(text("Articles"), timeout: -1)
    end
  end

  test "reload_page revisits the current path" do
    session =
      :static
      |> session()
      |> visit("/articles")

    reloaded = reload_page(session)

    assert reloaded.current_path == "/articles"
  end

  test "assert_path and refute_path support query matching" do
    assert is_struct(
             :static
             |> session()
             |> visit("/search")
             |> fill_in(label("Search term"), "phoenix")
             |> submit(button("Run Search"))
             |> assert_path("/search/results", query: %{q: "phoenix"})
             |> refute_path("/search/results", query: %{q: "elixir"})
           )
  end

  test "within scopes operations and restores session scope after callback" do
    session =
      :static
      |> session()
      |> visit("/scoped")
      |> within("#secondary-panel", fn scoped ->
        scoped
        |> assert_has(text("Secondary Panel"), exact: true)
        |> click(link("Open"))
      end)

    assert session.current_path == "/search"
    assert session.scope == nil
  end

  test "assert_path failures include normalized path and scope details" do
    error =
      assert_raise AssertionError, fn ->
        :static
        |> session()
        |> visit("/scoped")
        |> within("#secondary-panel", fn scoped ->
          assert_path(scoped, "/articles")
        end)
      end

    assert error.message =~ "assert_path failed"
    assert error.message =~ ~s(actual_path: "/scoped")
    assert error.message =~ ~s(scope: "#secondary-panel")
  end

  test "invalid assert_path query option is rejected" do
    assert_raise ArgumentError, ~r/:query must be a map, keyword list, or nil/, fn ->
      :static
      |> session()
      |> visit("/articles")
      |> assert_path("/articles", query: "bad")
    end
  end
end
