defmodule CerberusTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Phoenix.LiveViewTest, only: [element: 3, render_click: 1]

  alias Cerberus.Browser.Native, as: BrowserNative
  alias Cerberus.Driver.Browser
  alias Cerberus.Driver.Live
  alias Cerberus.Driver.Static
  alias ExUnit.AssertionError

  test "session constructor defaults to phoenix non-browser sessions" do
    assert %Static{} = session()
    assert %Static{} = session(:phoenix)
  end

  test "session(conn) reuses existing conn state" do
    %Static{conn: seeded_conn} = visit(session(), "/session/user/alice")

    assert %Static{} =
             seeded_conn
             |> session()
             |> visit("/session/user")
             |> assert_has(text("Session user: alice", exact: true))
  end

  test "session(conn) preserves cookie-backed auth state" do
    email = "session-carry-#{System.unique_integer([:positive])}@example.com"
    password = "Password12345!"

    %Static{conn: seeded_conn} =
      session()
      |> visit("/auth/static/users/register")
      |> fill_in(~l"Email"l, email)
      |> fill_in(~l"Password"l, password)
      |> fill_in(~l"Confirm Password"l, password)
      |> submit(role(:button, name: "Create account"))
      |> assert_path("/auth/static/dashboard")
      |> assert_has(text("Signed in as: #{email}", exact: true))

    seeded_conn
    |> session()
    |> visit("/auth/static/dashboard")
    |> assert_has(text("Signed in as: #{email}", exact: true))
  end

  test "session(conn) preserves init_test_session values before first request" do
    seeded_conn =
      Phoenix.ConnTest.build_conn()
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Plug.Conn.put_session(:session_user, "bob")

    seeded_conn
    |> session()
    |> visit("/session/user")
    |> assert_has(text("Session user: bob", exact: true))
  end

  test "session constructor rejects explicit auto/static/live driver selection" do
    assert_raise ArgumentError, ~r/unsupported public driver :auto/, fn ->
      session(:auto)
    end

    assert_raise ArgumentError, ~r/unsupported public driver :static/, fn ->
      session(:static)
    end

    assert_raise ArgumentError, ~r/unsupported public driver :live/, fn ->
      session(:live)
    end
  end

  test "chrome alias constructs browser sessions" do
    assert %Browser{} = session(:browser)
  end

  test "new-session isolation plus open_tab/switch_tab API works for non-browser sessions" do
    primary =
      session()
      |> visit("/session/user/alice")
      |> assert_has(text("Session user: alice", exact: true))

    tab =
      primary
      |> open_tab()
      |> visit("/session/user")
      |> assert_has(text("Session user: alice", exact: true))

    isolated_user =
      session()
      |> visit("/session/user")
      |> assert_has(text("Session user: unset", exact: true))

    switched = switch_tab(tab, primary)
    assert switched.current_path == "/session/user"

    closed = close_tab(tab)
    assert closed.current_path == "/session/user"
    assert isolated_user.current_path == "/session/user"
  end

  test "session constructor returns a browser session" do
    assert %Browser{} = session(:browser)
  end

  @tag :slow
  test "browser session applies init script and viewport defaults across new tabs" do
    session =
      :browser
      |> session(
        browser: [
          viewport: {900, 650},
          init_script: "window.__cerberusInit = 'ready';"
        ]
      )
      |> visit("/articles")

    assert Cerberus.Browser.evaluate_js(session, "window.__cerberusInit", fn result ->
             assert result == "ready"
           end)

    Cerberus.Browser.evaluate_js(
      session,
      "({ width: window.innerWidth, height: window.innerHeight })",
      fn %{"width" => width, "height" => height} ->
        assert is_integer(width) and width >= 880
        assert is_integer(height) and height >= 620
      end
    )

    tab2 =
      session
      |> open_tab()
      |> visit("/articles")

    Cerberus.Browser.evaluate_js(tab2, "window.__cerberusInit", &assert(&1 == "ready"))
  end

  test "switch_tab rejects mixed browser and non-browser sessions" do
    browser_tab =
      :browser
      |> session()
      |> visit("/articles")

    static_tab = visit(session(), "/articles")

    assert_raise ArgumentError, ~r/cannot switch browser tab to a non-browser session/, fn ->
      switch_tab(browser_tab, static_tab)
    end
  end

  test "assert_has rejects unsupported locator input type" do
    assert_raise FunctionClauseError, fn ->
      session()
      |> visit("/articles")
      |> assert_has(foo: "bar")
    end
  end

  test "assert_has accepts text sigil locator" do
    assert is_struct(
             session()
             |> visit("/articles")
             |> assert_has(~l"Articles"e)
           )
  end

  test "sigil modifiers support role, css, and testid locator flows" do
    session =
      session()
      |> visit("/articles")
      |> assert_has(~l"articles-title"t)
      |> click(~l"link:Counter"r)
      |> assert_has(~l"button:Increment"re)
      |> visit("/search")
      |> fill_in(~l"search-input"t, "phoenix")
      |> submit(~l"search-submit"t)
      |> assert_has(~l"Search query: phoenix"e)

    assert_path(session, "/search/results", query: %{q: "phoenix"})
  end

  test "click with label locator defers to driver matching while assertions treat label locators as text" do
    assert_raise AssertionError, ~r/no clickable element matched locator/, fn ->
      session()
      |> visit("/search")
      |> click(~l"Search term"l)
    end

    assert is_struct(
             session()
             |> visit("/search")
             |> assert_has(~l"Search term"l)
           )
  end

  test "helper locators work with click/assert/fill_in flows" do
    session =
      session()
      |> visit("/articles")
      |> click(role(:link, name: "Counter"))
      |> assert_has(role(:button, name: "Increment"))
      |> click(role(:button, name: "Increment"))
      |> assert_has(text("Count: 1"))

    assert_path(session, "/live/counter")

    assert is_struct(
             session()
             |> visit("/search")
             |> fill_in(~l"Search term"l, "phoenix")
           )
  end

  test "testid helper matches first-class test ids in assertions and actions" do
    session =
      session()
      |> visit("/articles")
      |> assert_has(testid("articles-title"))
      |> visit("/search")
      |> fill_in(testid("search-input"), "phoenix")
      |> submit(testid("search-submit"))

    assert_path(session, "/search/results", query: %{q: "phoenix"})
  end

  test "unsupported driver is rejected" do
    assert_raise ArgumentError, ~r/unsupported public driver/, fn ->
      session(:unknown)
    end
  end

  test "fill_in accepts positional value argument as a label shorthand" do
    assert is_struct(
             session()
             |> visit("/search")
             |> fill_in(~l"Search term"l, "phoenix")
           )
  end

  test "fill_in accepts explicit text locators" do
    assert is_struct(
             session()
             |> visit("/search")
             |> fill_in(text("Search term"), "phoenix")
           )
  end

  test "check and uncheck support label shorthand on checkbox groups" do
    checked =
      session()
      |> visit("/checkbox-array")
      |> check(~l"Two"l)
      |> submit(text("Save Items"))

    assert_has(checked, text("Selected Items: one,two", exact: true))

    unchecked =
      session()
      |> visit("/checkbox-array")
      |> uncheck(~l"One"l)
      |> submit(text("Save Items"))

    assert_has(unchecked, text("Selected Items: None", exact: true))
  end

  test "check accepts explicit text locators" do
    checked =
      session()
      |> visit("/checkbox-array")
      |> check(text("Two"))
      |> submit(text("Save Items"))

    assert_has(checked, text("Selected Items: one,two", exact: true))
  end

  test "select requires explicit locator options" do
    assert_raise ArgumentError, ~r/:option must be a text locator or list of text locators/, fn ->
      session()
      |> visit("/controls")
      |> select(~l"Race"l, option: "Dwarf")
    end
  end

  test "upload requires explicit locators and accepts explicit text locators" do
    jpg = "test/support/files/elixir.jpg"

    assert_raise ArgumentError, ~r/upload\/4 expects a non-empty path string and keyword options/, fn ->
      session()
      |> visit("/live/uploads")
      |> within(css("#upload-change-form"), fn scoped ->
        upload(scoped, "Avatar", jpg)
      end)
    end

    assert is_struct(
             session()
             |> visit("/live/uploads")
             |> within(css("#upload-change-form"), fn scoped ->
               upload(scoped, text("Avatar"), jpg)
             end)
           )
  end

  test "invalid keyword options are rejected via NimbleOptions" do
    assert_raise ArgumentError, ~r/invalid options/, fn ->
      session()
      |> visit("/articles")
      |> click(~l"Articles"e, nope: true)
    end
  end

  test "operation-level text matching options are rejected" do
    assert_raise ArgumentError, ~r/invalid options/, fn ->
      session()
      |> visit("/articles")
      |> click(role(:button, name: "Counter"), exact: true)
    end

    assert_raise ArgumentError, ~r/invalid options/, fn ->
      session()
      |> visit("/articles")
      |> assert_has(text("Articles"), exact: true)
    end

    assert_raise ArgumentError, ~r/invalid options/, fn ->
      session()
      |> visit("/articles")
      |> assert_has(text("Articles"), normalize_ws: false)
    end
  end

  test "assert_has timeout option must be non-negative integer" do
    assert_raise ArgumentError, ~r/invalid options/, fn ->
      session()
      |> visit("/articles")
      |> assert_has(text("Articles"), timeout: -1)
    end
  end

  test "action timeout options must be non-negative integers" do
    assert_raise ArgumentError, ~r/invalid value for :timeout option/, fn ->
      session()
      |> visit("/articles")
      |> click(text("Articles"), timeout: -1)
    end

    assert_raise ArgumentError, ~r/invalid value for :timeout option/, fn ->
      session()
      |> visit("/search")
      |> fill_in(~l"Search term"l, "Gandalf", timeout: -1)
    end

    assert_raise ArgumentError, ~r/invalid value for :timeout option/, fn ->
      session()
      |> visit("/controls")
      |> select(~l"Race"l, option: ~l"Elf"e, timeout: -1)
    end

    assert_raise ArgumentError, ~r/invalid value for :timeout option/, fn ->
      session()
      |> visit("/controls")
      |> choose(~l"Email Choice"l, timeout: -1)
    end

    assert_raise ArgumentError, ~r/invalid value for :timeout option/, fn ->
      session()
      |> visit("/controls")
      |> check(~l"Subscribe"l, timeout: -1)
    end

    assert_raise ArgumentError, ~r/invalid value for :timeout option/, fn ->
      session()
      |> visit("/controls")
      |> uncheck(~l"Subscribe"l, timeout: -1)
    end

    assert_raise ArgumentError, ~r/invalid value for :timeout option/, fn ->
      session()
      |> visit("/controls")
      |> submit(text("Save Controls"), timeout: -1)
    end

    assert_raise ArgumentError, ~r/invalid value for :timeout option/, fn ->
      session()
      |> visit("/live/uploads")
      |> upload(~l"Avatar"l, "test/support/files/elixir.jpg", timeout: -1)
    end
  end

  test "reload_page revisits the current path" do
    session = visit(session(), "/articles")

    reloaded = reload_page(session)

    assert_path(reloaded, "/articles")
  end

  test "open_browser creates an HTML snapshot for static sessions" do
    session =
      session()
      |> visit("/articles")
      |> open_browser(fn path ->
        send(self(), {:open_browser_snapshot, path})
      end)

    assert_path(session, "/articles")
    assert_receive {:open_browser_snapshot, path}
    assert File.exists?(path)
    assert File.read!(path) =~ "Articles"
    File.rm(path)
  end

  test "render_html yields a LazyHTML snapshot for static sessions" do
    session =
      session()
      |> visit("/articles")
      |> render_html(fn lazy_html ->
        send(self(), {:render_html_snapshot, lazy_html, Cerberus.Html.texts(lazy_html, :any, nil)})
      end)

    assert_path(session, "/articles")

    assert_receive {:render_html_snapshot, %LazyHTML{} = lazy_html, texts}
    assert is_list(texts)
    assert Enum.any?(texts, &String.contains?(&1, "Articles"))
    refute Enum.empty?(LazyHTML.query(lazy_html, "h1"))
  end

  test "render_html supports return_result option" do
    session = visit(session(), "/articles")

    assert render_html(session, []) == session

    lazy_html = render_html(session, return_result: true)

    assert %LazyHTML{} = lazy_html
    assert Enum.any?(Cerberus.Html.texts(lazy_html, :any, nil), &String.contains?(&1, "Articles"))

    assert_raise ArgumentError, ~r/render_html\/2 invalid options/, fn ->
      render_html(session, return_result: :yes)
    end
  end

  test "open_browser creates an HTML snapshot for live sessions" do
    session =
      session()
      |> visit("/live/counter")
      |> open_browser(fn path ->
        send(self(), {:open_browser_snapshot, path})
      end)

    assert_path(session, "/live/counter")
    assert_receive {:open_browser_snapshot, path}
    assert File.exists?(path)
    assert File.read!(path) =~ "Count: 0"
    File.rm(path)
  end

  test "render_html yields a LazyHTML snapshot for live sessions" do
    session =
      session()
      |> visit("/live/counter")
      |> render_html(fn lazy_html ->
        send(self(), {:render_html_snapshot, lazy_html, Cerberus.Html.texts(lazy_html, :any, nil)})
      end)

    assert_path(session, "/live/counter")

    assert_receive {:render_html_snapshot, %LazyHTML{} = lazy_html, texts}
    assert is_list(texts)
    assert Enum.any?(texts, &String.contains?(&1, "Count: 0"))
    assert Enum.count(LazyHTML.query(lazy_html, "body")) == 1
  end

  test "select and choose work for static and live sessions" do
    static_session =
      session()
      |> visit("/controls")
      |> select(~l"Race"l, option: ~l"Elf"e)
      |> choose(~l"Email Choice"l)
      |> submit(text("Save Controls"))

    assert String.starts_with?(static_session.current_path, "/controls/result")
    assert_has(static_session, text("race: elf", exact: true))
    assert_has(static_session, text("contact: email", exact: true))

    live_session =
      session()
      |> visit("/live/controls")
      |> select(~l"Race"l, option: ~l"Dwarf"e)
      |> choose(~l"Phone Choice"l)

    assert live_session.current_path == "/live/controls"
    assert_has(live_session, text("race: dwarf", exact: true))
    assert_has(live_session, text("contact: phone", exact: true))
  end

  test "select validates required option and choose validates radio targets" do
    assert_raise ArgumentError, ~r/select\/3 invalid options: required :option option/, fn ->
      session()
      |> visit("/controls")
      |> select(~l"Race"l)
    end

    choose_error =
      assert_raise AssertionError, fn ->
        session()
        |> visit("/controls")
        |> choose(~l"Race"l)
      end

    assert choose_error.message =~ "matched field is not a radio input"
  end

  test "assert_path and refute_path support query matching" do
    assert is_struct(
             session()
             |> visit("/search")
             |> fill_in(~l"Search term"l, "phoenix")
             |> submit(role(:button, name: "Run Search"))
             |> assert_path("/search/results", query: %{q: "phoenix"})
             |> refute_path("/search/results", query: %{q: "elixir"})
           )
  end

  test "within scopes operations and restores session scope after callback" do
    session =
      session()
      |> visit("/scoped")
      |> within(css("#secondary-panel"), fn scoped ->
        scoped
        |> assert_has(text("Secondary Panel", exact: true))
        |> click(role(:link, name: "Open"))
      end)

    assert session.current_path == "/search"
    assert session.scope == nil
  end

  test "within requires locator input and rejects raw string scopes" do
    assert_raise FunctionClauseError, fn ->
      session()
      |> visit("/scoped")
      |> within("#secondary-panel", fn scoped -> scoped end)
    end
  end

  test "assert_path failures include normalized path and scope details" do
    error =
      assert_raise AssertionError, fn ->
        session()
        |> visit("/scoped")
        |> within(css("#secondary-panel"), fn scoped ->
          assert_path(scoped, "/articles")
        end)
      end

    assert error.message =~ "assert_path failed"
    assert error.message =~ ~s(actual_path: "/scoped")
    assert error.message =~ "secondary-panel"
  end

  test "invalid assert_path query option is rejected" do
    assert_raise ArgumentError, ~r/:query must be a map, keyword list, or nil/, fn ->
      session()
      |> visit("/articles")
      |> assert_path("/articles", query: "bad")
    end
  end

  test "invalid assert_path timeout option is rejected" do
    assert_raise ArgumentError, ~r/invalid value for :timeout option/, fn ->
      session()
      |> visit("/articles")
      |> assert_path("/articles", timeout: -1)
    end
  end

  test "unwrap provides static conn escape hatch and keeps pipeline state" do
    session =
      session()
      |> visit("/articles")
      |> unwrap(fn conn ->
        Plug.Conn.put_req_header(conn, "x-custom-header", "unwrap-flow")
      end)
      |> visit("/main")
      |> assert_has(text("x-custom-header: unwrap-flow", exact: true))

    assert session.current_path == "/main"
  end

  test "unwrap follows static redirects returned from callback conn actions" do
    session =
      session()
      |> visit("/articles")
      |> unwrap(fn conn ->
        Phoenix.ConnTest.dispatch(
          conn,
          Cerberus.Fixtures.Endpoint,
          :get,
          "/redirect/live",
          %{}
        )
      end)
      |> assert_has(text("Count: 0", exact: true))

    assert %Live{} = session
    assert session.current_path == "/live/counter"
  end

  test "unwrap in live mode follows live redirects from render actions" do
    session =
      session()
      |> visit("/live/redirects")
      |> unwrap(fn view ->
        view
        |> element("button", "Redirect to Counter")
        |> render_click()
      end)
      |> assert_has(text("Count: 0", exact: true))

    assert session.current_path == "/live/counter"
  end

  test "unwrap in browser mode exposes constrained native browser handles" do
    session =
      :browser
      |> session()
      |> visit("/articles")
      |> unwrap(fn native ->
        send(self(), {:unwrap_native, native})
      end)

    assert_path(session, "/articles")

    assert_receive {:unwrap_native, %BrowserNative{} = native}

    user_context_pid = BrowserNative.user_context_pid(native)
    tab_id = BrowserNative.tab_id(native)

    assert is_pid(user_context_pid)
    assert is_binary(tab_id)
    assert tab_id != ""
  end

  test "open_browser creates an HTML snapshot for browser sessions" do
    session =
      :browser
      |> session()
      |> visit("/articles")
      |> open_browser(fn path ->
        send(self(), {:open_browser_snapshot, path})
      end)

    assert_path(session, "/articles")
    assert_receive {:open_browser_snapshot, path}
    assert File.exists?(path)
    assert File.read!(path) =~ "Articles"
    File.rm(path)
  end

  test "render_html yields a LazyHTML snapshot for browser sessions" do
    session =
      :browser
      |> session()
      |> visit("/articles")
      |> render_html(fn lazy_html ->
        send(self(), {:render_html_snapshot, lazy_html, Cerberus.Html.texts(lazy_html, :any, nil)})
      end)

    assert_path(session, "/articles")

    assert_receive {:render_html_snapshot, %LazyHTML{} = lazy_html, texts}
    assert is_list(texts)
    assert Enum.any?(texts, &String.contains?(&1, "Articles"))
    refute Enum.empty?(LazyHTML.query(lazy_html, "h1"))
  end

  test "unwrap rejects invalid callback arity" do
    assert_raise ArgumentError, ~r/callback with arity 1/, fn ->
      session()
      |> visit("/articles")
      |> unwrap(fn -> :ok end)
    end
  end

  test "unwrap rejects invalid static callback result values" do
    assert_raise ArgumentError, ~r/must return a Plug.Conn in static mode/, fn ->
      session()
      |> visit("/articles")
      |> unwrap(fn _conn -> :invalid end)
    end
  end

  test "unwrap rejects live sessions without an active LiveView" do
    assert_raise ArgumentError, ~r/requires an active LiveView/, fn ->
      unwrap(Live.new_session(), fn view -> view end)
    end
  end

  test "open_browser rejects invalid callback arity" do
    assert_raise ArgumentError, ~r/callback with arity 1/, fn ->
      session()
      |> visit("/articles")
      |> open_browser(fn -> :ok end)
    end
  end

  test "render_html rejects invalid callback arity" do
    assert_raise ArgumentError, ~r/callback with arity 1/, fn ->
      session()
      |> visit("/articles")
      |> render_html(fn -> :ok end)
    end
  end

  test "select and choose work for browser sessions" do
    browser_session =
      :browser
      |> session()
      |> visit("/controls")
      |> select(~l"Race"l, option: ~l"Dwarf"e)
      |> choose(~l"Email Choice"l)
      |> submit(text("Save Controls"))

    assert_path(browser_session, ~r|^/controls/result|, exact: false)
    assert_has(browser_session, text("race: dwarf", exact: true))
    assert_has(browser_session, text("contact: email", exact: true))
  end
end
