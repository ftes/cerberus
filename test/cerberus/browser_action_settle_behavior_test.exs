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

  test "browser visit treats mixed connected and disconnected live roots as ready", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/browser/readiness/mixed-live-roots")
    |> then(fn updated ->
      readiness = updated.last_result.observed.readiness
      assert is_map(readiness)
      assert readiness["reason"] == "settled"
      assert readiness["lastLiveState"] == "connected"
      updated
    end)
    |> assert_has(text("Mixed Live Roots", exact: true), timeout: 0)
  end

  test "browser navigation to mixed live roots still performs await_ready", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/browser/readiness/source")
    |> click(role(:link, name: "Open mixed roots", exact: true))
    |> then(fn updated ->
      readiness = updated.last_result.observed.readiness
      assert is_map(readiness)
      assert readiness["reason"] == "settled"
      assert readiness["lastLiveState"] == "connected"
      updated
    end)
    |> assert_path("/browser/readiness/mixed-live-roots")
  end

  @tag :slow
  test "browser visit recovers from disconnected live-root timeout when snapshot is available", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/browser/readiness/disconnected-live-root")
    |> then(fn updated ->
      readiness = updated.last_result.observed.readiness
      assert is_map(readiness)
      assert readiness["reason"] == "visit_snapshot_recovery"
      assert readiness["recoveredFrom"] == "browser readiness timeout"
      assert readiness["lastLiveState"] == "disconnected"
      updated
    end)
    |> assert_has(text("Disconnected Live Root", exact: true), timeout: 0)
  end

  @tag :slow
  test "browser visit reports post-navigation readiness failure with reached path", context do
    assert_raise ArgumentError,
                 ~r/browser visit reached \/browser\/readiness\/busy-live-root but post-navigation readiness failed: browser readiness timeout/,
                 fn ->
                   :browser
                   |> SharedBrowserSession.driver_session(context)
                   |> visit("/browser/readiness/busy-live-root")
                 end
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

  @tag :slow
  test "browser actions budget enough time for live connect resolve and settle phases", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/browser/actionability/long-budget")
    |> select(~l"Slow role"l, option: ~l"Analyst"e, timeout: 1_500)
    |> assert_has(text("selected", exact: true), timeout: 0)
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
