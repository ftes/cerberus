defmodule Cerberus.BrowserActionSettleBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Driver.Browser
  alias Cerberus.TestSupport.SharedBrowserSession

  setup_all do
    {owner_pid, browser_session} = SharedBrowserSession.start!()

    on_exit(fn ->
      SharedBrowserSession.stop(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  test "browser visit on live routes performs await_ready", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/live/counter")
    |> then(fn updated ->
      readiness = updated.last_result.observed.readiness
      assert is_map(readiness)
      assert updated.last_result.observed.driver == Browser
      refute readiness["reason"] == "in-action-settle"
      refute readiness["skippedAwaitReady"] == true
      updated
    end)
    |> assert_has(text("Count: 0", exact: true), timeout: 0)
  end

  test "browser click on live non-navigation actions still performs await_ready", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/live/counter")
    |> click(role(:button, name: "Increment", exact: true))
    |> then(fn updated ->
      readiness = updated.last_result.observed.readiness
      assert is_map(readiness)
      assert updated.last_result.observed.driver == Browser
      refute readiness["reason"] == "in-action-settle"
      refute readiness["skippedAwaitReady"] == true

      updated
    end)
    |> assert_has(text("Count: 1", exact: true))
  end

  test "browser submit on live non-navigation forms still performs await_ready", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/live/form-sync")
    |> fill_in(~l"Nickname (submit only)"l, "Aragorn")
    |> submit(role(:button, name: "Save No Change", exact: true))
    |> then(fn updated ->
      readiness = updated.last_result.observed.readiness
      assert is_map(readiness)
      assert updated.last_result.observed.driver == Browser
      refute readiness["reason"] == "in-action-settle"
      refute readiness["skippedAwaitReady"] == true

      updated
    end)
    |> assert_has(text("no-change submitted: Aragorn", exact: true))
  end

  test "browser click that navigates still performs await_ready", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/live/redirects")
    |> click(role(:link, name: "Navigate link", exact: true))
    |> then(fn updated ->
      readiness = updated.last_result.observed.readiness
      assert is_map(readiness)
      assert updated.last_result.observed.driver == Browser
      refute readiness["reason"] == "in-action-settle"
      refute readiness["skippedAwaitReady"] == true
      updated
    end)
    |> assert_path("/live/counter")
  end
end
