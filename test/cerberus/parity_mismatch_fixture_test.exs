defmodule Cerberus.ParityMismatchFixtureTest do
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
    test "parity static mismatch fixture is reachable in static and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/oracle/mismatch")
      |> assert_has(~l"Oracle mismatch static fixture marker"e)
    end

    test "parity live mismatch fixture is reachable in live and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/oracle/mismatch")
      |> assert_has(~l"Oracle mismatch live fixture marker"e)
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
