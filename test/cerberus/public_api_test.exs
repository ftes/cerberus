defmodule Cerberus.PublicApiTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Phoenix.LiveViewTest, only: [element: 3, render_click: 1]

  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.InvalidLocatorError
  alias ExUnit.AssertionError

  test "session constructor defaults to phoenix non-browser sessions" do
    assert %StaticSession{} = session()
    assert %StaticSession{} = session(:phoenix)
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

  @tag :firefox
  test "chrome/firefox aliases construct browser sessions" do
    assert %BrowserSession{} = session(:chrome)
    assert %BrowserSession{} = session(:firefox)
  end

  test "open_user/open_tab/switch_tab API works for non-browser sessions" do
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
      primary
      |> open_user()
      |> visit("/session/user")
      |> assert_has(text("Session user: unset", exact: true))

    switched = switch_tab(tab, primary)
    assert switched.current_path == "/session/user"

    closed = close_tab(tab)
    assert closed.current_path == "/session/user"
    assert isolated_user.current_path == "/session/user"
  end

  test "session constructor returns a browser session" do
    assert %BrowserSession{} = session(:browser)
  end

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

    assert Cerberus.Browser.evaluate_js(session, "window.__cerberusInit") == "ready"

    dimensions =
      Cerberus.Browser.evaluate_js(
        session,
        "({ width: window.innerWidth, height: window.innerHeight })"
      )

    assert is_integer(dimensions["width"]) and dimensions["width"] >= 880
    assert is_integer(dimensions["height"]) and dimensions["height"] >= 620

    tab2 =
      session
      |> open_tab()
      |> visit("/articles")

    assert Cerberus.Browser.evaluate_js(tab2, "window.__cerberusInit") == "ready"
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

  test "assert_has with unsupported locator raises InvalidLocatorError" do
    assert_raise InvalidLocatorError, fn ->
      session()
      |> visit("/articles")
      |> assert_has(foo: "bar")
    end
  end

  test "assert_has accepts text sigil locator" do
    assert is_struct(
             session()
             |> visit("/articles")
             |> assert_has(~l"Articles")
           )
  end

  test "sigil modifiers support role and css locator flows" do
    session =
      session()
      |> visit("/articles")
      |> click(~l"link:Counter"r)
      |> assert_has(~l"button:Increment"re)
      |> visit("/search")
      |> fill_in(~l"#search_q"c, "phoenix")
      |> submit(~l"button[type='submit']"c)
      |> assert_has(~l"Search query: phoenix"e)

    assert session.current_path == "/search/results?q=phoenix"
  end

  test "label locators are explicit to fill_in; click rejects while assertions treat as text" do
    assert_raise InvalidLocatorError, ~r/label locators target form-field lookup/, fn ->
      session()
      |> visit("/search")
      |> click(label("Search term"))
    end

    assert is_struct(
             session()
             |> visit("/search")
             |> assert_has(label("Search term"))
           )
  end

  test "helper locators work with click/assert/fill_in flows" do
    session =
      session()
      |> visit("/articles")
      |> click(link("Counter"))
      |> assert_has(role(:button, name: "Increment"))
      |> click(button("Increment"))
      |> assert_has(text("Count: 1"))

    assert session.current_path == "/live/counter"

    assert is_struct(
             session()
             |> visit("/search")
             |> fill_in(label("Search term"), "phoenix")
           )
  end

  test "testid helper is explicit about unsupported operations in this slice" do
    assert_raise InvalidLocatorError, ~r/testid locators are not yet supported/, fn ->
      session()
      |> visit("/articles")
      |> assert_has(testid("articles-title"))
    end
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
             |> fill_in("Search term", "phoenix")
           )
  end

  test "fill_in rejects explicit text locators to keep label semantics explicit" do
    assert_raise InvalidLocatorError, ~r/text locators are not supported for fill_in\/4/, fn ->
      session()
      |> visit("/search")
      |> fill_in(text("Search term"), "phoenix")
    end
  end

  test "check and uncheck support label shorthand on checkbox groups" do
    checked =
      session()
      |> visit("/checkbox-array")
      |> check("Two")
      |> submit(text("Save Items"))

    assert_has(checked, text("Selected Items: one,two", exact: true))

    unchecked =
      session()
      |> visit("/checkbox-array")
      |> uncheck("One")
      |> submit(text("Save Items"))

    assert_has(unchecked, text("Selected Items: None", exact: true))
  end

  test "check rejects explicit text locators to keep label semantics explicit" do
    assert_raise InvalidLocatorError, ~r/text locators are not supported for check\/3/, fn ->
      session()
      |> visit("/checkbox-array")
      |> check(text("Two"))
    end
  end

  test "upload accepts string labels and rejects explicit text locators" do
    jpg = Path.expand("../support/files/elixir.jpg", __DIR__)

    assert is_struct(
             session()
             |> visit("/live/uploads")
             |> within("#upload-change-form", fn scoped ->
               upload(scoped, "Avatar", jpg)
             end)
           )

    assert_raise InvalidLocatorError, ~r/text locators are not supported for upload\/4/, fn ->
      session()
      |> visit("/live/uploads")
      |> within("#upload-change-form", fn scoped ->
        upload(scoped, text("Avatar"), jpg)
      end)
    end
  end

  test "invalid keyword options are rejected via NimbleOptions" do
    assert_raise ArgumentError, ~r/invalid options/, fn ->
      session()
      |> visit("/articles")
      |> click([text: "Articles"], kind: :nope)
    end
  end

  test "operation-level text matching options are rejected" do
    assert_raise ArgumentError, ~r/invalid options/, fn ->
      session()
      |> visit("/articles")
      |> click(button("Counter"), exact: true)
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

  test "reload_page revisits the current path" do
    session = visit(session(), "/articles")

    reloaded = reload_page(session)

    assert reloaded.current_path == "/articles"
  end

  test "open_browser creates an HTML snapshot for static sessions" do
    session =
      session()
      |> visit("/articles")
      |> open_browser(fn path ->
        send(self(), {:open_browser_snapshot, path})
      end)

    assert session.current_path == "/articles"
    assert_receive {:open_browser_snapshot, path}
    assert File.exists?(path)
    assert File.read!(path) =~ "Articles"
    File.rm(path)
  end

  test "open_browser creates an HTML snapshot for live sessions" do
    session =
      session()
      |> visit("/live/counter")
      |> open_browser(fn path ->
        send(self(), {:open_browser_snapshot, path})
      end)

    assert session.current_path == "/live/counter"
    assert_receive {:open_browser_snapshot, path}
    assert File.exists?(path)
    assert File.read!(path) =~ "Count: 0"
    File.rm(path)
  end

  test "screenshot is explicit unsupported for static and live sessions" do
    static_error =
      assert_raise AssertionError, fn ->
        session()
        |> visit("/articles")
        |> screenshot()
      end

    assert static_error.message =~ "screenshot is not implemented for :static driver"

    live_error =
      assert_raise AssertionError, fn ->
        session()
        |> visit("/live/counter")
        |> screenshot(path: "tmp/ignored.png")
      end

    assert live_error.message =~ "screenshot is not implemented for :live driver"
  end

  test "select and choose work for static and live sessions" do
    static_session =
      session()
      |> visit("/controls")
      |> select("Race", option: "Elf")
      |> choose("Email Choice")
      |> submit(text("Save Controls"))

    assert String.starts_with?(static_session.current_path, "/controls/result")
    assert_has(static_session, text("race: elf", exact: true))
    assert_has(static_session, text("contact: email", exact: true))

    live_session =
      session()
      |> visit("/live/controls")
      |> select("Race", option: "Dwarf")
      |> choose("Phone Choice")

    assert live_session.current_path == "/live/controls"
    assert_has(live_session, text("race: dwarf", exact: true))
    assert_has(live_session, text("contact: phone", exact: true))
  end

  test "select validates required option and choose validates radio targets" do
    assert_raise ArgumentError, ~r/select\/3 invalid options: required :option option/, fn ->
      session()
      |> visit("/controls")
      |> select("Race")
    end

    choose_error =
      assert_raise AssertionError, fn ->
        session()
        |> visit("/controls")
        |> choose("Race")
      end

    assert choose_error.message =~ "matched field is not a radio input"
  end

  test "assert_path and refute_path support query matching" do
    assert is_struct(
             session()
             |> visit("/search")
             |> fill_in(label("Search term"), "phoenix")
             |> submit(button("Run Search"))
             |> assert_path("/search/results", query: %{q: "phoenix"})
             |> refute_path("/search/results", query: %{q: "elixir"})
           )
  end

  test "within scopes operations and restores session scope after callback" do
    session =
      session()
      |> visit("/scoped")
      |> within("#secondary-panel", fn scoped ->
        scoped
        |> assert_has(text("Secondary Panel", exact: true))
        |> click(link("Open"))
      end)

    assert session.current_path == "/search"
    assert session.scope == nil
  end

  test "assert_path failures include normalized path and scope details" do
    error =
      assert_raise AssertionError, fn ->
        session()
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

    assert %LiveSession{} = session
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

  test "unwrap in browser mode exposes native tab handles" do
    session =
      :browser
      |> session()
      |> visit("/articles")
      |> unwrap(fn native ->
        send(self(), {:unwrap_native, native})
      end)

    assert session.current_path == "/articles"

    assert_receive {:unwrap_native, %{user_context_pid: user_context_pid, tab_id: tab_id}}
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

    assert session.current_path == "/articles"
    assert_receive {:open_browser_snapshot, path}
    assert File.exists?(path)
    assert File.read!(path) =~ "Articles"
    File.rm(path)
  end

  @tag :tmp_dir
  test "screenshot captures browser PNG output to a requested path", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "cerberus-screenshot.png")

    session =
      :browser
      |> session()
      |> visit("/articles")
      |> screenshot(path)

    assert session.current_path == "/articles"
    assert File.exists?(path)

    png = File.read!(path)
    assert byte_size(png) > 0
    assert :binary.part(png, 0, 8) == <<137, 80, 78, 71, 13, 10, 26, 10>>
    File.rm(path)
  end

  test "screenshot defaults to a temp PNG path and records it in last_result" do
    session =
      :browser
      |> session()
      |> visit("/articles")
      |> screenshot()

    assert %{op: :screenshot, observed: %{path: path, full_page: false}} = session.last_result
    assert File.exists?(path)
    assert String.ends_with?(path, ".png")
    File.rm(path)
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
      unwrap(LiveSession.new_session(), fn view -> view end)
    end
  end

  test "open_browser rejects invalid callback arity" do
    assert_raise ArgumentError, ~r/callback with arity 1/, fn ->
      session()
      |> visit("/articles")
      |> open_browser(fn -> :ok end)
    end
  end

  test "screenshot rejects invalid options" do
    assert_raise ArgumentError, ~r/:path must be a non-empty string path/, fn ->
      :browser
      |> session()
      |> visit("/articles")
      |> screenshot(path: "")
    end
  end

  test "select and choose work for browser sessions" do
    browser_session =
      :browser
      |> session()
      |> visit("/controls")
      |> select("Race", option: "Dwarf")
      |> choose("Email Choice")
      |> submit(text("Save Controls"))

    assert String.starts_with?(browser_session.current_path, "/controls/result")
    assert_has(browser_session, text("race: dwarf", exact: true))
    assert_has(browser_session, text("contact: email", exact: true))
  end
end
