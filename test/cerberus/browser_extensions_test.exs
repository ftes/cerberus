defmodule Cerberus.BrowserExtensionsTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Cerberus.Browser

  alias Cerberus.Driver.Browser.UserContextProcess
  alias ExUnit.AssertionError

  test "browser-only APIs are explicit unsupported on static and live sessions" do
    static = visit(session(), "/articles")

    static_error =
      assert_raise AssertionError, fn ->
        type(static, "hello")
      end

    assert static_error.message =~ "type is not implemented for :static driver"

    live = visit(session(), "/live/counter")

    live_error =
      assert_raise AssertionError, fn ->
        evaluate_js(live, "(() => 2 + 2)()")
      end

    assert live_error.message =~ "evaluate_js is not implemented for :live driver"

    live_callback_error =
      assert_raise AssertionError, fn ->
        evaluate_js(live, "(() => 2 + 2)()", fn _value -> :ok end)
      end

    assert live_callback_error.message =~ "evaluate_js is not implemented for :live driver"

    static_popup_error =
      assert_raise AssertionError, fn ->
        with_popup(static, fn s -> s end, fn _main, _popup -> :ok end)
      end

    assert static_popup_error.message =~ "with_popup is not implemented for :static driver"

    live_popup_error =
      assert_raise AssertionError, fn ->
        with_popup(live, fn s -> s end, fn _main, _popup -> :ok end)
      end

    assert live_popup_error.message =~ "with_popup is not implemented for :live driver"
  end

  @tag :tmp_dir
  test "screenshot + keyboard + dialog + drag browser extensions work together", %{tmp_dir: tmp_dir} do
    # NOTE: ExUnit :tmp_dir paths are deterministic for module+test. If multiple
    # mix test processes execute this same test in one checkout concurrently,
    # one process can remove this directory while another still reads artifacts.
    path = Path.join(tmp_dir, "cerberus-browser-extensions.png")

    session =
      :browser
      |> session()
      |> visit("/browser/extensions")
      |> screenshot(path: path)
      |> type("hello browser", selector: "#keyboard-input")
      |> press("Enter", selector: "#press-input")
      |> with_dialog(fn dialog_session ->
        click(dialog_session, button("Open Confirm Dialog"))
      end)

    assert File.exists?(path)
    assert evaluate_js(session, "document.querySelector('#keyboard-input').value") == "hello browser"

    session = drag(session, "#drag-source", "#drop-target")

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

    assert evaluate_js(session, "(() => 21 + 21)()") == 42

    assert evaluate_js(session, "(() => ({name: 'cerberus', nested: {count: 2}}))()") == %{
             "name" => "cerberus",
             "nested" => %{"count" => 2}
           }

    session = add_cookie(session, "cerberus-browser-cookie", "cookie-value")

    cookie = cookie(session, "cerberus-browser-cookie")
    assert cookie
    assert cookie.value == "cookie-value"
    assert cookie.path == "/"

    assert Enum.any?(cookies(session), fn entry ->
             entry.name == "cerberus-browser-cookie" and entry.value == "cookie-value"
           end)

    session =
      session
      |> visit("/session/user/alice")
      |> visit("/session/user")

    fixture_session_cookie = session_cookie(session)
    assert fixture_session_cookie
    assert fixture_session_cookie.name == "_cerberus_fixture_key"
    assert fixture_session_cookie.http_only
    assert fixture_session_cookie.session
  end

  test "evaluate_js supports optional callback assertions and returns session for chaining" do
    session =
      :browser
      |> session()
      |> visit("/articles")

    returned_session =
      evaluate_js(session, "(() => 21 + 21)()", fn value ->
        assert value == 42
      end)

    assert returned_session == session

    assert_raise AssertionError, fn ->
      evaluate_js(session, "(() => 40 + 1)()", fn value ->
        assert value == 42
      end)
    end
  end

  test "with_popup captures popup tab, yields main+popup sessions, and returns canonical main session" do
    main =
      :browser
      |> session()
      |> visit("/browser/popup/click")

    returned_main =
      with_popup(
        main,
        fn trigger_session ->
          click(trigger_session, button("Open Popup"))
        end,
        fn callback_main, popup ->
          assert callback_main.tab_id == main.tab_id
          assert popup.tab_id != callback_main.tab_id

          assert_path(callback_main, "/browser/popup/click")

          popup
          |> assert_path("/browser/popup/destination", query: %{source: "click-trigger"})
          |> assert_has(text("Popup Destination", exact: true))
          |> assert_has(text("popup source: click-trigger", exact: true))
        end
      )

    assert returned_main.tab_id == main.tab_id
    assert UserContextProcess.active_tab(returned_main.user_context_pid) == returned_main.tab_id
    assert_path(returned_main, "/browser/popup/click")
    assert_has(returned_main, text("Popup opened", exact: true))
  end

  test "with_popup times out when trigger does not open popup" do
    session =
      :browser
      |> session()
      |> visit("/browser/popup/click")

    error =
      assert_raise AssertionError, fn ->
        with_popup(
          session,
          fn trigger_session ->
            trigger_session
          end,
          fn _main, _popup ->
            :ok
          end,
          timeout: 25
        )
      end

    assert error.message == "with_popup/4 timed out waiting for popup tab"
  end

  test "with_popup surfaces callback failure and restores main tab" do
    session =
      :browser
      |> session()
      |> visit("/browser/popup/click")

    error =
      assert_raise AssertionError, fn ->
        with_popup(
          session,
          fn trigger_session ->
            click(trigger_session, button("Open Popup"))
          end,
          fn _main, popup ->
            assert_path(popup, "/browser/popup/destination", query: %{source: "click-trigger"})
            raise "popup callback exploded"
          end
        )
      end

    assert error.message =~ "with_popup/4 callback failed:"
    assert error.message =~ "popup callback exploded"
    assert UserContextProcess.active_tab(session.user_context_pid) == session.tab_id
  end

  test "with_dialog reports callback completion when no dialog opens" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    error =
      assert_raise AssertionError, fn ->
        with_dialog(session, fn dialog_session ->
          dialog_session
        end)
      end

    assert error.message =~
             "with_dialog/3 callback completed before browsingContext.userPromptOpened was observed"
  end

  test "with_dialog raises when observed dialog message does not match expected message" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    error =
      assert_raise AssertionError, fn ->
        with_dialog(
          session,
          fn dialog_session ->
            click(dialog_session, button("Open Confirm Dialog"))
          end,
          message: "Different message"
        )
      end

    assert error.message =~ ~s(expected message "Different message")
    assert error.message =~ ~s(observed "Delete item?")
  end

  test "with_dialog timeout reports waiting for prompt open when callback stays pending" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    error =
      assert_raise AssertionError, fn ->
        with_dialog(
          session,
          fn dialog_session ->
            _ = dialog_session
            Process.sleep(100)
            dialog_session
          end,
          timeout: 25
        )
      end

    assert error.message =~ "with_dialog/3 timed out waiting for browsingContext.userPromptOpened"
  end

  test "with_dialog ignores callback return value and returns refreshed main session" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")
      |> visit("/browser/popup/click")

    returned_session =
      with_dialog(session, fn dialog_session ->
        dialog_session
        |> visit("/browser/extensions")
        |> click(button("Open Confirm Dialog"))

        :ignored
      end)

    assert returned_session.tab_id == session.tab_id
    assert UserContextProcess.active_tab(returned_session.user_context_pid) == returned_session.tab_id
    assert_path(returned_session, "/browser/extensions")
    assert_has(returned_session, text("Dialog result: cancelled", exact: true))
  end

  test "with_dialog surfaces callback failures after dialog handling" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    error =
      assert_raise AssertionError, fn ->
        with_dialog(session, fn dialog_session ->
          click(dialog_session, button("Open Confirm Dialog"))
          Process.sleep(10)
          raise "dialog callback exploded"
        end)
      end

    assert error.message =~ "with_dialog/3 callback failed:"
    assert error.message =~ "dialog callback exploded"
  end
end
