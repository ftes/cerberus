defmodule Cerberus.LiveNavigationTest do
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
    test "dynamic counter updates are consistent between live and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/counter")
      |> click(~l"Increment"e)
      |> assert_has(~l"Count: 1"e)
    end

    test "live redirects are deterministic in live and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/redirects")
      |> click(~l"Redirect to Articles"e)
      |> assert_has(~l"Articles"e)
      |> visit("/live/redirects")
      |> click(~l"Redirect to Counter"e)
      |> assert_has(~l"Count: 0"e)
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
