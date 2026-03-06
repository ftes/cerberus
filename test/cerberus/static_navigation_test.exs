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
      |> click(~l"Counter"e)
      |> assert_has(~l"Count: 0"e)
    end

    test "static session auto-switches to live for dynamic button interactions (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/counter")
      |> click(~l"Increment"e)
      |> assert_has(~l"Count: 1"e)
    end

    test "static redirects are deterministic and stay inside fixture routes (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/redirect/static")
      |> assert_has(~l"Articles"e)
      |> visit("/redirect/live")
      |> assert_has(~l"Count: 0"e)
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
