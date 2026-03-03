defmodule Cerberus.StaticNavigationTest do
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
    test "static driver supports link navigation into deterministic page state (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/articles")
      |> click(text: "Counter")
      |> assert_has(text: "Count: 0", exact: true)
    end

    test "static session auto-switches to live for dynamic button interactions (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/counter")
      |> click(text: "Increment")
      |> assert_has(text: "Count: 1", exact: true)
    end

    test "static redirects are deterministic and stay inside fixture routes (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/redirect/static")
      |> assert_has(text: "Articles")
      |> visit("/redirect/live")
      |> assert_has(text: "Count: 0", exact: true)
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
