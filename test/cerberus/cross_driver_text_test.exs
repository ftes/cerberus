defmodule Cerberus.CrossDriverTextTest do
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
    test "text assertions behave consistently for static pages in static and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/articles")
      |> assert_has(~l"Articles"e)
      |> assert_has(text(~r/articles index/i))
      |> refute_has(~l"500 Internal Server Error"e)
      |> assert_has(~l"Hidden helper text"e, visible: false)
    end

    test "assert_has failure includes candidate hints (#{driver})", context do
      error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> driver_session(context)
          |> visit("/articles")
          |> assert_has(~l"Definitely Missing Text"e, timeout: 50)
        end

      assert error.message =~ "possible candidates:"
      assert error.message =~ "Articles"
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
