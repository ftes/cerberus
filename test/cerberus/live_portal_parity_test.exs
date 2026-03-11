defmodule Cerberus.LivePortalParityTest do
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
    test "portal button click works across drivers (#{driver})", context do
      unquote(driver)
      |> SharedBrowserSession.driver_session(context)
      |> visit("/live/portal")
      |> assert_has(text("Portal count: 0", exact: true))
      |> assert_has(text("Outside count: 0", exact: true))
      |> click(role(:button, name: "Increment portal", exact: true))
      |> assert_has(text("Portal count: 1", exact: true))
      |> assert_has(text("Outside count: 1", exact: true))
    end
  end
end
