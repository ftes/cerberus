defmodule Cerberus.TimeoutBehaviorParityTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.TestSupport.SharedBrowserSession

  setup_all do
    {owner_pid, browser_session} = SharedBrowserSession.start!()

    on_exit(fn ->
      SharedBrowserSession.stop(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "timeout waits for async assigns (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/async_page")
      |> assert_has(text("Title loaded async"), timeout: 350)
    end

    test "timeout handles multi-live async transitions (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/async_page")
      |> click(button("Async navigate to async 2 page!"))
      |> assert_has(text("Another title loaded async"), timeout: 350)
      |> assert_path("/live/async_page_2")
    end

    test "timeout handles async redirects and refute_has transitions (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/async_page")
      |> click(button("Async redirect!"))
      |> refute_has(text("Where we test LiveView's async behavior"), timeout: 350)
      |> assert_path("/articles")
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
