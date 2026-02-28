defmodule Cerberus.CoreBrowserTimeoutAssertionsTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.Harness

  @moduletag :browser

  test "browser defaults use 500ms assertion timeout and wait for async text", context do
    Harness.run!(context, fn session ->
      assert session.assert_timeout_ms == 500

      session
      |> visit("/live/async_page")
      |> assert_has(text("Title loaded async"))
    end)
  end

  test "browser default timeout waits for async navigate path updates", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/async_page")
      |> click_button(button("Async navigate!"))
      |> assert_path("/live/counter")
    end)
  end

  test "browser default timeout waits for async redirect path updates", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/async_page")
      |> click_button(button("Async redirect!"))
      |> assert_path("/articles")
    end)
  end
end
