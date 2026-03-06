defmodule Cerberus.PhoenixTest.ParitySmokeTest do
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
    test "visits prefixed static fixture and follows static link (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/page/index")
      |> assert_has(and_(css("h1"), text("Main page")))
      |> click(role(:link, name: "Page 2"))
      |> assert_has(and_(css("h1"), text("Page 2")))
    end

    test "visits prefixed live fixture directly (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> assert_has(and_(css("h1"), text("LiveView main page")))
    end

    test "submits prefixed static form (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/page/index")
      |> fill_in(label("Email"), "parity@example.com")
      |> click(role(:button, name: "Save Email"))
      |> assert_path("/phoenix_test/page/create_record")
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
