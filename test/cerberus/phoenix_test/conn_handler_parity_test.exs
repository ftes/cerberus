defmodule Cerberus.PhoenixTest.ConnHandlerParityTest do
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
    test "visit navigates to live page (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> assert_has(and_(css("h1"), text("LiveView main page")))
    end

    test "visit navigates to static page (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/page/index")
      |> assert_has(and_(css("h1"), text("Main page")))
    end

    test "visit follows live mount redirect (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/redirect_on_mount/redirect")
      |> assert_has(and_(css("h1"), text("LiveView main page")))
    end

    test "visit follows push navigate redirect (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/redirect_on_mount/push_navigate")
      |> assert_has(and_(css("h1"), text("LiveView main page")))
    end

    test "visit follows static redirect (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/page/redirect_to_static")
      |> assert_has(and_(css("h1"), text("Main page")))
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
