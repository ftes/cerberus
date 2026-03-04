defmodule Cerberus.LiveTimeoutAssertionsTest do
  use ExUnit.Case, async: true

  import Cerberus

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
    |> click(button("Async navigate!"))
    |> assert_path("/live/counter")
  end

  test "live default timeout waits for async redirect path updates" do
    :phoenix
    |> session()
    |> visit("/live/async_page")
    |> click(button("Async redirect!"))
    |> assert_path("/articles")
  end
end
