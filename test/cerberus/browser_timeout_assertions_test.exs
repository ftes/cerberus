defmodule Cerberus.BrowserTimeoutAssertionsTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Cerberus.Browser, only: [with_evaluate_js: 3]

  setup_all do
    {:ok, browser_session: session(:browser)}
  end

  test "browser defaults use 500ms assertion timeout and wait for async text", %{browser_session: browser_session} do
    session = browser_fixture_session(browser_session, "/live/async_page")
    assert session.timeout_ms == 500

    assert_has(session, text("Title loaded async"))
  end

  test "browser default timeout waits for async navigate path updates", %{browser_session: browser_session} do
    browser_session
    |> browser_fixture_session("/live/async_page")
    |> click(role(:button, name: "Async navigate!"))
    |> assert_path("/live/counter")
  end

  test "browser assertion eval retries across async navigation context resets", %{browser_session: browser_session} do
    browser_session
    |> browser_fixture_session("/live/async_page")
    |> click(role(:button, name: "Async navigate!"))
    |> assert_has(text("Count: 0"), timeout: 500)
    |> assert_path("/live/counter", timeout: 500)
  end

  test "browser timeout handles async redirect path updates", %{browser_session: browser_session} do
    browser_session
    |> browser_fixture_session("/live/async_page")
    |> click(role(:button, name: "Async redirect!"))
    |> assert_path("/articles", timeout: 2_000)
  end

  test "browser session timeout is used for action waits when call timeout is absent" do
    :browser
    |> session(timeout_ms: 600)
    |> visit("/live/actionability/delayed")
    |> select(~l"Category"l, option: ~l"Advanced"e)
    |> select(~l"Role"l, option: ~l"Analyst"e)
    |> assert_has(text("role: analyst", exact: true))
  end

  test "browser assert_path falls back to direct URL checks when helper is missing", %{browser_session: browser_session} do
    session =
      browser_session
      |> browser_fixture_session("/articles")
      |> with_evaluate_js(
        "(() => { delete window.__cerberusAssert; return window.__cerberusAssert == null; })()",
        fn helper_missing? -> assert helper_missing? end
      )

    assert_path(session, "/articles")
  end

  defp browser_fixture_session(session, path) when is_binary(path) do
    visit(session, path)
  end
end
