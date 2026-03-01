defmodule Cerberus.CoreBrowserTimeoutAssertionsTest do
  use ExUnit.Case, async: true

  import Cerberus

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
end
