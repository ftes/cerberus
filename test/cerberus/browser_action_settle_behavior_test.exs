defmodule Cerberus.BrowserActionSettleBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Driver.Browser.UserContextProcess
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
      readiness = last_readiness(updated)
      assert is_map(readiness)
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
      readiness = last_readiness(updated)
      assert is_map(readiness)
      assert readiness["reason"] == "settled"
      assert readiness["lastLiveState"] == "connected"
      updated
    end)
    |> assert_has(text("Mixed Live Roots", exact: true), timeout: 0)
  end

  test "browser link navigation to mixed live roots performs post-click readiness", context do
    session =
      :browser
      |> SharedBrowserSession.driver_session(context)
      |> visit("/browser/readiness/source")

    session
    |> click(role(:link, name: "Open mixed roots", exact: true))
    |> assert_path("/browser/readiness/mixed-live-roots")
    |> then(fn updated ->
      readiness = last_readiness(updated)
      assert is_map(readiness)
      assert readiness["reason"] == "settled"
      assert readiness["path"] == "/browser/readiness/mixed-live-roots"
      assert readiness["lastLiveState"] == "connected"
      updated
    end)
  end

  test "browser visit recovers from disconnected live-root timeout when snapshot is available", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/browser/readiness/disconnected-live-root")
    |> then(fn updated ->
      readiness = last_readiness(updated)
      assert is_map(readiness)
      assert readiness["reason"] == "timeout"
      assert readiness["lastLiveState"] == "disconnected"
      updated
    end)
    |> assert_has(text("Disconnected Live Root", exact: true), timeout: 0)
  end

  test "browser visit treats ongoing connected-root churn as ready", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/browser/readiness/busy-live-root")
    |> then(fn updated ->
      readiness = last_readiness(updated)
      assert is_map(readiness)
      assert readiness["reason"] == "settled"
      assert readiness["lastLiveState"] == "connected"
      updated
    end)
    |> assert_has(text("Busy Live Root", exact: true), timeout: 0)
  end

  test "browser click on live non-navigation actions does not force post-action readiness", context do
    session =
      :browser
      |> SharedBrowserSession.driver_session(context)
      |> visit("/live/counter")

    readiness = last_readiness(session)

    session
    |> click(role(:button, name: "Increment", exact: true))
    |> assert_has(text("Count: 1", exact: true))
    |> then(fn updated ->
      assert last_readiness(updated) == readiness
      updated
    end)
  end

  test "browser label clicks on live form controls do not force post-action readiness", context do
    session =
      :browser
      |> SharedBrowserSession.driver_session(context)
      |> visit("/live/controls")

    readiness = last_readiness(session)

    session
    |> click(css("label[for='live_controls_contact_email']"))
    |> assert_has(text("contact: email", exact: true))
    |> then(fn updated ->
      assert last_readiness(updated) == readiness
      updated
    end)
  end

  test "browser actions budget enough time for pre-action resolve and leave settle to the next assertion", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/browser/actionability/long-budget")
    |> select(~l"Slow role"l, ~l"Analyst"e, timeout: 1_500)
    |> assert_has(text("selected", exact: true), timeout: 1_500)
  end

  test "browser submit on live non-navigation forms does not force post-action readiness", context do
    session =
      :browser
      |> SharedBrowserSession.driver_session(context)
      |> visit("/live/form-sync")
      |> fill_in(~l"Nickname (submit only)"l, "Aragorn")

    readiness = last_readiness(session)

    session
    |> submit(role(:button, name: "Save No Change", exact: true))
    |> assert_has(text("no-change submitted: Aragorn", exact: true))
    |> then(fn updated ->
      assert last_readiness(updated) == readiness
      updated
    end)
  end

  test "browser click that navigates can still await when navigation is already observed", context do
    :browser
    |> SharedBrowserSession.driver_session(context)
    |> visit("/live/redirects")
    |> click(role(:link, name: "Navigate link", exact: true))
    |> then(fn updated ->
      readiness = last_readiness(updated)
      assert is_map(readiness)
      assert readiness["reason"] == "settled"
      updated
    end)
    |> assert_path("/live/counter")
  end

  defp last_readiness(session) do
    UserContextProcess.last_readiness(session.user_context_pid, session.tab_id)
  end
end
