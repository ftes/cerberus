defmodule Cerberus.FormActionsTest do
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
    test "click_link, fill_in, and submit are consistent across static and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> click_link(text: "Articles")
      |> assert_has(text: "Articles", exact: true)
      |> visit("/search")
      |> fill_in("Search term", "phoenix")
      |> submit(text: "Run Search")
      |> assert_has(text: "Search query: phoenix", exact: true)
    end

    test "submit/1 submits the first submit-capable control in scope (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> fill_in("Search term", "compat")
      |> submit()
      |> assert_has(text: "Search query: compat", exact: true)
    end

    test "fill_in matches wrapped labels with nested inline text across static and browser drivers (#{driver})",
         context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> fill_in("Search term *", "phoenix")
      |> submit(text: "Run Nested Search")
      |> assert_has(text: "Nested search query: phoenix", exact: true)
    end

    test "click_button works on live counter flow for live and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/counter")
      |> click_button(text: "Increment")
      |> assert_has(text: "Count: 1", exact: true)
    end
  end

  test "live driver reports missing fields for fill_in and missing submit controls on counter page" do
    assert_raise ExUnit.AssertionError, ~r/no form field matched locator/, fn ->
      :phoenix
      |> session()
      |> visit("/live/counter")
      |> fill_in("Search term", "x")
    end

    assert_raise ExUnit.AssertionError, ~r/no submit button matched locator/, fn ->
      :phoenix
      |> session()
      |> visit("/live/counter")
      |> submit(text: "Run Search")
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
