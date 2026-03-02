defmodule Cerberus.BrowserTimeoutAssertionsTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Cerberus.Browser, only: [evaluate_js: 3]

  test "browser defaults use 500ms assertion timeout and wait for async text" do
    session = session(:browser)
    assert session.assert_timeout_ms == 500

    session
    |> visit("/live/async_page")
    |> assert_has(text("Title loaded async"))
  end

  test "browser default timeout waits for async navigate path updates" do
    :browser
    |> session()
    |> visit("/live/async_page")
    |> click_button(button("Async navigate!"))
    |> assert_path("/live/counter")
  end

  test "browser default timeout waits for async redirect path updates" do
    :browser
    |> session()
    |> visit("/live/async_page")
    |> click_button(button("Async redirect!"))
    |> assert_path("/articles")
  end

  test "browser assert_path falls back to direct URL checks when helper is missing" do
    session =
      :browser
      |> session()
      |> visit("/articles")
      |> evaluate_js(
        "(() => { delete window.__cerberusAssert; return window.__cerberusAssert == null; })()",
        fn helper_missing? -> assert helper_missing? end
      )

    assert_path(session, "/articles")
  end
end
