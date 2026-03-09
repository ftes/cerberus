defmodule Cerberus.BrowserExtensionsTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Cerberus.Browser

  alias Cerberus.Driver.Browser.UserContextProcess
  alias Cerberus.Fixtures.Endpoint
  alias ExUnit.AssertionError

  test "browser-only APIs are explicit unsupported on static and live sessions" do
    static = visit(session(), "/articles")

    static_error =
      assert_raise AssertionError, fn ->
        type(static, css("#keyboard-input"), "hello")
      end

    assert static_error.message =~ "type is not implemented for :static driver"

    live = visit(session(), "/live/counter")

    live_callback_error =
      assert_raise AssertionError, fn ->
        evaluate_js(live, "(() => 2 + 2)()", fn _value -> :ok end)
      end

    assert live_callback_error.message =~ "evaluate_js is not implemented for :live driver"

    live_no_callback_error =
      assert_raise AssertionError, fn ->
        evaluate_js(live, "(() => 2 + 2)()")
      end

    assert live_no_callback_error.message =~ "evaluate_js is not implemented for :live driver"

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
      |> type(css("#keyboard-input"), "hello browser")
      |> press(css("#press-input"), "Enter")

    evaluate_js(session, "setTimeout(() => document.getElementById('confirm-dialog')?.click(), 10)", fn _ -> :ok end)
    session = assert_dialog(session, text("Delete item?", exact: true))

    assert File.exists?(path)

    assert evaluate_js(session, "document.querySelector('#keyboard-input').value", fn value ->
             assert value == "hello browser"
           end)

    assert evaluate_js(session, "document.querySelector('#keyboard-keydown-count').textContent", fn value ->
             assert value == "Keyboard keydown count: 13"
           end)

    session = drag(session, "#drag-source", "#drop-target")

    assert_has(session, text("Press result: submitted", exact: true))
    assert_has(session, text("Dialog result: confirmed", exact: true))
    assert_has(session, text("Drag result: dropped", exact: true))

    png = File.read!(path)
    assert :binary.part(png, 0, 8) == <<137, 80, 78, 71, 13, 10, 26, 10>>
    File.rm(path)
  end

  test "press uses real keyboard semantics for printable keys, editing keys, and Tab focus traversal" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")
      |> press(css("#press-input"), "a")
      |> press(css("#press-input"), "Space")
      |> press(css("#press-input"), "KeyB")

    evaluate_js(session, "document.querySelector('#press-input').value", &assert(&1 == "a b"))

    session = press(session, css("#press-input"), "Backspace")
    evaluate_js(session, "document.querySelector('#press-input').value", &assert(&1 == "a "))

    session =
      session
      |> type(css("#tab-input"), "blur me")
      |> press(css("#tab-input"), "Tab")

    assert_has(session, text("Blur result: blurred", exact: true))
    assert_has(session, text("Tab result: focused next", exact: true))
    evaluate_js(session, "document.activeElement && document.activeElement.id", &assert(&1 == "tab-next"))
  end

  test "click rejects hidden targets via actionability visibility checks" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    error =
      assert_raise AssertionError, fn ->
        click(session, role(:button, name: "Hidden Action", exact: true))
      end

    assert error.message =~ "matched element is not visible"
  end

  test "force bypasses browser actionability visibility checks" do
    :browser
    |> session()
    |> visit("/browser/extensions")
    |> click(:button |> role(name: "Hidden Action", exact: true) |> filter(visible: false), force: true)
    |> assert_has(text("Hidden action result: clicked", exact: true))
  end

  test "click scrolls offscreen targets into view before acting" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    evaluate_js(session, "window.scrollY", &assert(&1 == 0))

    session =
      session
      |> click(role(:button, name: "Offscreen Action", exact: true))
      |> assert_has(text("Offscreen action result: clicked", exact: true))

    evaluate_js(session, "window.scrollY", &assert(&1 > 0))
  end

  test "click can target plain label elements in the browser" do
    :browser
    |> session()
    |> visit("/browser/extensions")
    |> click(css("#checkbox-label"))
    |> assert_has(text("Label click result: checked", exact: true))
  end

  test "evaluate_js and cookie helpers cover add_cookies, clear_cookies, and session cookie semantics" do
    session =
      :browser
      |> session()
      |> visit("/articles")

    evaluate_js(session, "(() => 21 + 21)()", &assert(&1 == 42))

    evaluate_js(
      session,
      "(() => ({name: 'cerberus', nested: {count: 2}}))()",
      &assert(
        &1 == %{
          "name" => "cerberus",
          "nested" => %{"count" => 2}
        }
      )
    )

    session =
      add_cookies(session, [
        [name: "cerberus-browser-cookie", value: "cookie-value"],
        [
          name: "cerberus-browser-url-cookie",
          value: "url-cookie-value",
          url: Endpoint.url() <> "/articles"
        ]
      ])

    cookie = cookie(session, "cerberus-browser-cookie")
    assert cookie
    assert cookie.value == "cookie-value"
    assert cookie.path == "/"

    assert cookie(session, "cerberus-browser-cookie", fn entry ->
             send(self(), {:cookie_callback, entry})
           end) == session

    assert_receive {:cookie_callback, %{name: "cerberus-browser-cookie", value: "cookie-value"}}

    assert Enum.any?(cookies(session), fn entry ->
             entry.name == "cerberus-browser-cookie" and entry.value == "cookie-value"
           end)

    assert cookies(session, fn entries ->
             send(self(), {:cookies_callback, entries})
           end) == session

    assert_receive {:cookies_callback, entries}
    assert Enum.any?(entries, &(&1.name == "cerberus-browser-cookie" and &1.value == "cookie-value"))
    assert Enum.any?(entries, &(&1.name == "cerberus-browser-url-cookie" and &1.value == "url-cookie-value"))

    session =
      session
      |> clear_cookies()
      |> add_session_cookie(
        [value: %{session_user: "alice"}],
        Endpoint.session_options()
      )
      |> visit("/session/user")

    refute cookie(session, "cerberus-browser-cookie")

    fixture_session_cookie = session_cookie(session)
    assert fixture_session_cookie
    assert fixture_session_cookie.name == "_cerberus_fixture_key"
    assert fixture_session_cookie.http_only
    assert fixture_session_cookie.session

    assert_has(session, text("Session user: alice", exact: true))

    assert session_cookie(session, fn entry ->
             send(self(), {:session_cookie_callback, entry})
           end) == session

    assert_receive {:session_cookie_callback, %{name: "_cerberus_fixture_key"}}
  end

  test "browser keyword options are validated with NimbleOptions" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    assert_raise ArgumentError, ~r/Browser.type\/4 invalid options/, fn ->
      type(session, css("#keyboard-input"), "hello", unknown: true)
    end

    assert_raise ArgumentError, ~r/Browser.press\/4 invalid options/, fn ->
      press(session, css("#press-input"), "Enter", timeout: -1)
    end

    assert_raise ArgumentError, ~r/Browser.drag\/4 invalid options/, fn ->
      drag(session, "#drag-source", "#drop-target", timeout: -1)
    end

    assert_raise ArgumentError, ~r/Browser.assert_dialog\/3 invalid options/, fn ->
      assert_dialog(session, text("Delete item?"), accept: :yes)
    end

    assert_raise ArgumentError, ~r/Browser.with_popup\/4 invalid options/, fn ->
      with_popup(session, fn scoped -> scoped end, fn _main, _popup -> :ok end, timeout: 0)
    end

    assert_raise ArgumentError, ~r/assert_download\/3 invalid options/, fn ->
      assert_download(session, "report.txt", timeout: 0)
    end

    assert_raise ArgumentError, ~r/Browser.add_cookie\/4 invalid options/, fn ->
      add_cookie(session, "cerberus-browser-cookie", "cookie-value", path: "")
    end

    assert_raise ArgumentError, ~r/Browser.add_cookies\/2 invalid options: :name must be a non-empty string/, fn ->
      add_cookies(session, [[value: "cookie-value"]])
    end

    assert_raise ArgumentError, ~r/Browser.clear_cookies\/2 invalid options/, fn ->
      clear_cookies(session, timeout: -1)
    end

    assert_raise ArgumentError, ~r/Browser.add_session_cookie\/3 invalid options: :value must be a map/, fn ->
      add_session_cookie(session, [value: "bad"], Endpoint.session_options())
    end
  end

  test "evaluate_js supports callback, ignore-result, and return_result forms" do
    session =
      :browser
      |> session()
      |> visit("/articles")

    assert evaluate_js(session, "(() => 21 + 21)()") == session

    returned_session =
      evaluate_js(session, "(() => 21 + 21)()", fn value ->
        assert value == 42
      end)

    assert returned_session == session
    assert evaluate_js(session, "(() => 9 * 9)()", return_result: true) == 81

    assert_raise ArgumentError, ~r/Browser.evaluate_js\/3 invalid options/, fn ->
      evaluate_js(session, "(() => 9 * 9)()", return_result: :yes)
    end

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
          click(trigger_session, role(:button, name: "Open Popup"))
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

  @tag :slow
  test "with_popup waits for popup opened after waiter registration" do
    main =
      :browser
      |> session()
      |> visit("/browser/popup/click")

    returned_main =
      with_popup(
        main,
        fn trigger_session ->
          Process.sleep(35)
          click(trigger_session, role(:button, name: "Open Popup"))
        end,
        fn callback_main, popup ->
          assert callback_main.tab_id == main.tab_id
          assert popup.tab_id != callback_main.tab_id
          assert_path(popup, "/browser/popup/destination", query: %{source: "click-trigger"})
        end,
        timeout: 1_000
      )

    assert returned_main.tab_id == main.tab_id
    assert UserContextProcess.active_tab(returned_main.user_context_pid) == returned_main.tab_id
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
            click(trigger_session, role(:button, name: "Open Popup"))
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

  @tag :slow
  test "assert_dialog handles a dialog that is already open" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    trigger_confirm_dialog(session)
    Process.sleep(25)

    assert_dialog(session, text("Delete item?", exact: true))
    assert_has(session, text("Dialog result: confirmed", exact: true))
  end

  @tag :slow
  test "assert_dialog waits for a dialog that opens after assertion starts" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    trigger_confirm_dialog(session, 30)
    assert_dialog(session, text("Delete item?", exact: true))
    assert_has(session, text("Dialog result: confirmed", exact: true))
  end

  @tag skip: "browser actions no longer auto-unblock dialogs"
  test "click action completes when clicked target opens a blocking prompt dialog" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")
      |> click(role(:button, name: "Open Prompt Dialog", exact: true))

    assert_prompt_result(session, "Prompt result: ")
  end

  @tag skip: "browser actions no longer auto-unblock dialogs"
  test "click action completes when clicked target opens a blocking confirm dialog" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")
      |> click(role(:button, name: "Open Confirm Dialog", exact: true))

    assert_dialog(session, text("Delete item?", exact: true))
    assert_has(session, text("Dialog result: confirmed", exact: true))
  end

  @tag :slow
  test "assertion operations complete when a blocking prompt dialog is already open" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    trigger_prompt_dialog(session)
    Process.sleep(50)

    session = assert_has(session, text("Browser Extensions", exact: true), timeout: 500)
    assert_prompt_result(session, "Prompt result: ")
  end

  @tag :slow
  test "assertion operations complete when a blocking alert dialog is already open" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    trigger_alert_dialog(session)
    Process.sleep(50)

    session = assert_has(session, text("Browser Extensions", exact: true), timeout: 500)
    assert_has(session, text("Alert result: acknowledged", exact: true))
  end

  test "assert_download matches download emitted before assertion call and keeps events non-consuming" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")
      |> click(role(:link, name: "Download Report"))

    assert_download(session, "report.txt")
    assert_download(session, "report.txt")
  end

  @tag :slow
  test "assert_download waits for download emitted after assertion starts" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    evaluate_js(session, "setTimeout(() => document.getElementById('download-report')?.click(), 30)", fn _ -> :ok end)
    assert_download(session, "report.txt", timeout: 1_500)
  end

  test "assert_download supports static sessions from controller download responses" do
    session =
      session()
      |> visit("/browser/extensions")
      |> click(role(:link, name: "Download Report"))

    assert_download(session, "report.txt")
  end

  test "assert_download supports live sessions redirecting to controller download responses" do
    session =
      session()
      |> visit("/live/counter")
      |> click(role(:link, name: "Download Report"))

    assert_download(session, "report.txt")
  end

  for driver <- [:phoenix, :browser] do
    @tag :slow
    test "assert_download waits for delayed live redirect to static download response (#{driver})" do
      session =
        unquote(driver)
        |> session()
        |> visit("/live/counter")
        |> click(role(:button, name: "Delayed Download"))

      assert_download(session, "report.txt", timeout: 1_500)
    end
  end

  test "assert_download fails on active live routes before download navigation" do
    session = visit(session(), "/live/counter")

    error =
      assert_raise AssertionError, fn ->
        assert_download(session, "report.txt", timeout: 25)
      end

    assert error.message =~ "assert_download/3 timed out waiting for live download redirect"
  end

  test "assert_download reports observed filenames for static/live responses" do
    session =
      session()
      |> visit("/browser/extensions")
      |> click(role(:link, name: "Download Report"))

    error =
      assert_raise AssertionError, fn ->
        assert_download(session, "missing.txt")
      end

    assert error.message =~ ~s(assert_download/3 expected "missing.txt")
    assert error.message =~ "report.txt"
  end

  test "assert_download times out with helpful observed filenames" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")
      |> click(role(:link, name: "Download Report"))

    error =
      assert_raise AssertionError, fn ->
        assert_download(session, "missing.txt", timeout: 50)
      end

    assert error.message =~ ~s(assert_download/3 timed out waiting for "missing.txt")
    assert error.message =~ "report.txt"
  end

  @tag :slow
  test "assert_dialog raises when observed dialog message does not match expected text" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    trigger_confirm_dialog(session)
    Process.sleep(25)

    error =
      assert_raise AssertionError, fn ->
        assert_dialog(session, text("Different message", exact: true))
      end

    assert error.message =~ ~s(expected dialog text "Different message")
    assert error.message =~ ~s(observed "Delete item?")
    assert_has(session, text("Dialog result: confirmed", exact: true))
  end

  test "assert_dialog times out when no dialog opens" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    error =
      assert_raise AssertionError, fn ->
        assert_dialog(session, text("Delete item?", exact: true), timeout: 25)
      end

    assert error.message =~ "assert_dialog/3 timed out waiting for dialog text \"Delete item?\""
  end

  @tag :slow
  test "assert_dialog supports prompt dialogs with auto-accepted empty input" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    trigger_prompt_dialog(session, 30)
    assert_dialog(session, text("Type value", exact: true))
    assert_prompt_result(session, "Prompt result: ")
  end

  @tag :slow
  test "assert_dialog supports alert dialogs" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    trigger_alert_dialog(session, 30)
    assert_dialog(session, text("Heads up!", exact: true))
    assert_has(session, text("Alert result: acknowledged", exact: true))
  end

  test "assert_dialog rejects explicit dialog control options" do
    session =
      :browser
      |> session()
      |> visit("/browser/extensions")

    assert_raise ArgumentError, ~r/Browser.assert_dialog\/3 invalid options/, fn ->
      assert_dialog(session, text("Delete item?"), accept: true)
    end

    assert_raise ArgumentError, ~r/Browser.assert_dialog\/3 invalid options/, fn ->
      assert_dialog(session, text("Delete item?"), prompt_text: "42")
    end
  end

  defp trigger_confirm_dialog(session, delay_ms \\ 0) when is_integer(delay_ms) and delay_ms >= 0 do
    evaluate_js(session, "setTimeout(() => document.getElementById('confirm-dialog')?.click(), #{delay_ms})", fn _ ->
      :ok
    end)
  end

  defp trigger_prompt_dialog(session, delay_ms \\ 0) when is_integer(delay_ms) and delay_ms >= 0 do
    evaluate_js(session, "setTimeout(() => document.getElementById('prompt-dialog')?.click(), #{delay_ms})", fn _ ->
      :ok
    end)
  end

  defp trigger_alert_dialog(session, delay_ms \\ 0) when is_integer(delay_ms) and delay_ms >= 0 do
    evaluate_js(session, "setTimeout(() => document.getElementById('alert-dialog')?.click(), #{delay_ms})", fn _ ->
      :ok
    end)
  end

  defp assert_prompt_result(session, expected) when is_binary(expected) do
    evaluate_js(session, "document.getElementById('prompt-result')?.textContent", fn value ->
      assert value == expected
    end)
  end
end
