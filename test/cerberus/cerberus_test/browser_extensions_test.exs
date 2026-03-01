defmodule CerberusTest.BrowserExtensionsTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Browser
  alias ExUnit.AssertionError

  test "browser-only APIs are explicit unsupported on static and live sessions" do
    static = visit(session(), "/articles")

    static_error =
      assert_raise AssertionError, fn ->
        Browser.type(static, "hello")
      end

    assert static_error.message =~ "type is not implemented for :static driver"

    live = visit(session(), "/live/counter")

    live_error =
      assert_raise AssertionError, fn ->
        Browser.evaluate_js(live, "(() => 2 + 2)()")
      end

    assert live_error.message =~ "evaluate_js is not implemented for :live driver"
  end

  @tag :tmp_dir
  test "screenshot + keyboard + dialog + drag browser extensions work together", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "cerberus-browser-extensions.png")

    session =
      :browser
      |> session()
      |> visit("/browser/extensions")
      |> Browser.screenshot(path: path)
      |> Browser.type("hello browser", selector: "#keyboard-input")
      |> Browser.press("Enter", selector: "#press-input")
      |> Browser.with_dialog(fn dialog_session ->
        click(dialog_session, button("Open Confirm Dialog"))
      end)

    assert File.exists?(path)
    assert Browser.evaluate_js(session, "document.querySelector('#keyboard-input').value") == "hello browser"
    assert session.last_result.op == :with_dialog
    assert session.last_result.observed.message == "Delete item?"
    assert session.last_result.observed.accepted == false

    session = Browser.drag(session, "#drag-source", "#drop-target")

    assert_has(session, text("Press result: submitted", exact: true))
    assert_has(session, text("Dialog result: cancelled", exact: true))
    assert_has(session, text("Drag result: dropped", exact: true))

    png = File.read!(path)
    assert :binary.part(png, 0, 8) == <<137, 80, 78, 71, 13, 10, 26, 10>>
    File.rm(path)
  end

  test "evaluate_js and cookie helpers cover add_cookie and session cookie semantics" do
    session =
      :browser
      |> session()
      |> visit("/articles")

    assert Browser.evaluate_js(session, "(() => 21 + 21)()") == 42

    assert Browser.evaluate_js(session, "(() => ({name: 'cerberus', nested: {count: 2}}))()") == %{
             "name" => "cerberus",
             "nested" => %{"count" => 2}
           }

    session = Browser.add_cookie(session, "cerberus-browser-cookie", "cookie-value")

    assert session.last_result.op == :add_cookie

    cookie = Browser.cookie(session, "cerberus-browser-cookie")
    assert cookie
    assert cookie.value == "cookie-value"
    assert cookie.path == "/"

    assert Enum.any?(Browser.cookies(session), fn entry ->
             entry.name == "cerberus-browser-cookie" and entry.value == "cookie-value"
           end)

    session =
      session
      |> visit("/session/user/alice")
      |> visit("/session/user")

    fixture_session_cookie = Browser.session_cookie(session)
    assert fixture_session_cookie
    assert fixture_session_cookie.name == "_cerberus_fixture_key"
    assert fixture_session_cookie.http_only
    assert fixture_session_cookie.session
  end
end
