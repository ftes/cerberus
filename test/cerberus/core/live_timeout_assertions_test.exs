defmodule Cerberus.CoreLiveTimeoutAssertionsTest do
  use ExUnit.Case, async: true

  import Cerberus

  test "timeout waits for async assigns" do
    :phoenix
    |> session()
    |> visit("/live/async_page")
    |> assert_has(text("Title loaded async"), timeout: 350)
  end

  test "timeout handles async navigate transitions" do
    :phoenix
    |> session()
    |> visit("/live/async_page")
    |> click_button(button("Async navigate!"))
    |> assert_has(text("Count: 0"), timeout: 350)
    |> assert_path("/live/counter")
  end

  test "timeout handles multi-live async transitions" do
    :phoenix
    |> session()
    |> visit("/live/async_page")
    |> click_button(button("Async navigate to async 2 page!"))
    |> assert_has(text("Another title loaded async"), timeout: 350)
    |> assert_path("/live/async_page_2")
  end

  test "timeout handles async redirects" do
    :phoenix
    |> session()
    |> visit("/live/async_page")
    |> click_button(button("Async redirect!"))
    |> refute_has(text("Where we test LiveView's async behavior"), timeout: 350)
    |> assert_path("/articles")
  end

  test "live defaults use 500ms assertion timeout and wait for async navigate path updates" do
    session =
      :phoenix
      |> session()
      |> visit("/live/async_page")

    session
    |> then(fn live_session ->
      assert live_session.assert_timeout_ms == 500
      live_session
    end)
    |> click_button(button("Async navigate!"))
    |> assert_path("/live/counter")
  end

  test "live default timeout waits for async redirect path updates" do
    :phoenix
    |> session()
    |> visit("/live/async_page")
    |> click_button(button("Async redirect!"))
    |> assert_path("/articles")
  end
end
