defmodule Cerberus.ApiExamplesTest do
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
    test "static page text presence and absence use public API example flow (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/articles")
      |> assert_has(text("Articles"))
      |> assert_has(text("This is an articles index page"))
      |> refute_has(text("500 Internal Server Error"))
    end

    test "same counter click example runs in live and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/counter")
      |> click(role(:button, name: "Increment"))
      |> assert_has(text("Count: 1", exact: true))
    end

    test "failure messages include locator and options for reproducible debugging (#{driver})", context do
      error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> driver_session(context)
          |> visit("/articles")
          |> assert_has([text: "DOES NOT EXIST", exact: true], timeout: 0)
        end

      assert error.message =~ "assert_has failed"
      assert error.message =~ ~s(locator: [text: "DOES NOT EXIST", exact: true])
      assert error.message =~ "opts:"
      assert error.message =~ "visible: true"
      assert error.message =~ ~r/timeout: (0|500)/
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
