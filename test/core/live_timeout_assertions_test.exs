defmodule Cerberus.CoreLiveTimeoutAssertionsTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag :conformance
  @moduletag drivers: [:live]

  test "timeout waits for async assigns", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/async_page")
      |> assert_has(text("Title loaded async"), timeout: 350)
    end)
  end

  test "timeout handles async navigate transitions", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/async_page")
      |> click_button(button("Async navigate!"))
      |> assert_has(text("Count: 0"), timeout: 350)
      |> assert_path("/live/counter")
    end)
  end

  test "timeout handles multi-live async transitions", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/async_page")
      |> click_button(button("Async navigate to async 2 page!"))
      |> assert_has(text("Another title loaded async"), timeout: 350)
      |> assert_path("/live/async_page_2")
    end)
  end

  test "timeout handles async redirects", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/async_page")
      |> click_button(button("Async redirect!"))
      |> refute_has(text("Where we test LiveView's async behavior"), timeout: 350)
      |> assert_path("/articles")
    end)
  end

  test "live defaults use 500ms assertion timeout and wait for async navigate path updates", context do
    Harness.run!(context, fn session ->
      assert session.assert_timeout_ms == 500

      session
      |> visit("/live/async_page")
      |> click_button(button("Async navigate!"))
      |> assert_path("/live/counter")
    end)
  end

  test "live default timeout waits for async redirect path updates", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/async_page")
      |> click_button(button("Async redirect!"))
      |> assert_path("/articles")
    end)
  end
end
