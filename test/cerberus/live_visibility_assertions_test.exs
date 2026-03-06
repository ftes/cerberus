defmodule Cerberus.LiveVisibilityAssertionsTest do
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
    test "live assertions support visible filters (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/counter")
      |> refute_has(text("Hidden live helper text"), visible: true)
      |> assert_has(text("Hidden live helper text"), visible: false)
      |> assert_has(text("Hidden live helper text"), visible: :any)
    end

    test "live assertions support locator-level visible filters (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/counter")
      |> assert_has(filter(text("Hidden live helper text"), visible: false))
      |> refute_has(filter(text("Hidden live helper text"), visible: true))
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
