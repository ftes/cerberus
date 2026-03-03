defmodule Cerberus.BrowserActionSettleBehaviorTest do
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

  test "browser click on live non-navigation actions can skip await_ready", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/live/counter")
    |> click_button(button("Increment", exact: true))
    |> then(fn updated ->
      assert %{"reason" => "in-action-settle", "skippedAwaitReady" => true} =
               updated.last_result.observed.readiness

      updated
    end)
    |> assert_has(text("Count: 1", exact: true))
  end

  test "browser submit on live non-navigation forms can skip await_ready", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/live/form-sync")
    |> fill_in("Nickname (submit only)", "Aragorn")
    |> submit(button("Save No Change", exact: true))
    |> then(fn updated ->
      assert %{"reason" => "in-action-settle", "skippedAwaitReady" => true} =
               updated.last_result.observed.readiness

      updated
    end)
    |> assert_has(text("no-change submitted: Aragorn", exact: true))
  end

  test "browser click that navigates still performs await_ready", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/live/redirects")
    |> click_link(link("Navigate link", exact: true))
    |> then(fn updated ->
      readiness = updated.last_result.observed.readiness
      assert is_map(readiness)
      refute readiness["reason"] == "in-action-settle"
      refute readiness["skippedAwaitReady"] == true
      updated
    end)
    |> assert_path("/live/counter")
  end
end
