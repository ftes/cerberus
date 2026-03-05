defmodule Cerberus.PhoenixTest.LiveInteractionsParityTest do
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
    test "visits prefixed live fixture (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> assert_has(and_(css("h1"), text("LiveView main page")))
    end

    test "follows navigate link in live fixture (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> click(link("Navigate link"))
      |> assert_has(and_(css("h1"), text("LiveView page 2")))
    end

    test "follows patch link in live fixture (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> click(link("Patch link"))
      |> assert_has(and_(css("h2"), text("LiveView main page details")))
    end

    test "navigates from live fixture to static fixture (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> click(link("Navigate to non-liveview"))
      |> assert_has(and_(css("h1"), text("Main page")))
    end

    test "handles phx-click button interaction in live fixture (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> click(button("Show tab"))
      |> assert_has(and_(css("#tab"), text("Tab title")))
    end

    test "handles push navigate button interaction in live fixture (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> click(button("Button with push navigation"))
      |> assert_has(and_(css("h1"), text("LiveView page 2")))
    end

    test "handles push patch button interaction in live fixture (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> click(button("Button with push patch"))
      |> assert_path("/phoenix_test/live/index", query: %{foo: "bar"})
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
