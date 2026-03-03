defmodule Cerberus.BrowserLinkClickSemanticsTest do
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

  test "click_link honors preventDefault when navigation is cancelled", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/browser/link/semantics")
    |> click_link(link("Prevented link", exact: true))
    |> assert_path("/browser/link/semantics")
    |> assert_has(text("Link result: prevented", exact: true))
  end

  test "click_link follows JS-intercepted navigation target", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/browser/link/semantics")
    |> click_link(link("Intercepted link", exact: true))
    |> assert_path("/main", query: [from: "intercepted"])
    |> assert_has(text("Main page", exact: true))
  end
end
