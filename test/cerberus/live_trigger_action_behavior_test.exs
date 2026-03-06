defmodule Cerberus.LiveTriggerActionBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.TestSupport.SharedBrowserSession
  alias ExUnit.AssertionError

  setup_all do
    {owner_pid, browser_session} = SharedBrowserSession.start!()

    on_exit(fn ->
      SharedBrowserSession.stop(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "phx-trigger-action submits to static endpoint after phx-submit (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/trigger-action")
      |> fill_in(~l"Trigger action"l, "engage")
      |> submit(~l"Submit Trigger Form"e)
      |> assert_path("/trigger-action/result")
      |> assert_has(text("method: POST", exact: true))
    end

    test "submit/1 uses the active live form without an explicit button locator (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/trigger-action")
      |> fill_in(~l"Trigger action"l, "engage")
      |> submit()
      |> assert_path("/trigger-action/result")
      |> assert_has(text("method: POST", exact: true))
    end

    test "phx-trigger-action can be triggered from outside the form (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/trigger-action")
      |> click(~l"Trigger from elsewhere"e)
      |> assert_path("/trigger-action/result")
      |> assert_has(text("method: POST", exact: true))
    end

    test "phx-trigger-action is ignored when click event redirects or navigates (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/trigger-action")
      |> click(~l"Redirect and trigger action"e)
      |> assert_path("/live/counter")
      |> assert_has(text("Counter", exact: true))
      |> visit("/live/trigger-action")
      |> click(~l"Navigate and trigger action"e)
      |> assert_path("/live/counter")
      |> assert_has(text("Counter", exact: true))
    end

    test "dynamically rendered forms can trigger action submit (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/trigger-action")
      |> click(~l"Show Dynamic Form"e)
      |> fill_in(~l"Message"l, "dynamic")
      |> submit(~l"Submit Dynamic Form"e)
      |> assert_path("/trigger-action/result")
      |> assert_has(text("method: POST", exact: true))
    end
  end

  test "live driver keeps default hidden payload when triggered from outside form" do
    :phoenix
    |> session()
    |> visit("/live/trigger-action")
    |> click(~l"Trigger from elsewhere"e)
    |> assert_path("/trigger-action/result")
    |> assert_has(text("trigger_action_hidden_input: trigger_action_hidden_value", exact: true))
    |> refute_has(text("trigger_action_input: engage", exact: true))
  end

  test "live driver submits merged payload for trigger-action handoff" do
    :phoenix
    |> session()
    |> visit("/live/trigger-action")
    |> fill_in(~l"Trigger action"l, "engage")
    |> submit(~l"Submit Trigger Form"e)
    |> assert_path("/trigger-action/result")
    |> assert_has(text("trigger_action_hidden_input: trigger_action_hidden_value", exact: true))
    |> assert_has(text("trigger_action_input: engage", exact: true))
  end

  test "phx-trigger-action runs after patch-producing phx-change" do
    :phoenix
    |> session()
    |> visit("/live/trigger-action")
    |> fill_in(~l"Patch and trigger action"l, "let's go")
    |> assert_path("/trigger-action/result")
    |> assert_has(text("patch_and_trigger_action: let's go", exact: true))
  end

  test "live driver submits dynamic form payload on trigger-action handoff" do
    :phoenix
    |> session()
    |> visit("/live/trigger-action")
    |> click(~l"Show Dynamic Form"e)
    |> fill_in(~l"Message"l, "dynamic")
    |> submit(~l"Submit Dynamic Form"e)
    |> assert_path("/trigger-action/result")
    |> assert_has(text("message: dynamic", exact: true))
  end

  test "data-method buttons on live pages submit to static endpoints (phoenix)" do
    :phoenix
    |> session()
    |> visit("/live/trigger-action")
    |> click(role(:button, name: "Data-method Trigger Action", exact: true))
    |> assert_path("/trigger-action/result")
    |> assert_has(text("method: POST", exact: true))
  end

  @tag skip: "browser data-method button parity bug"
  test "data-method buttons on live pages submit to static endpoints (browser)", context do
    context.shared_browser_session
    |> visit("/live/trigger-action")
    |> click(role(:button, name: "Data-method Trigger Action", exact: true))
    |> assert_path("/trigger-action/result")
    |> assert_has(text("method: POST", exact: true))
  end

  test "raises an error if multiple forms have phx-trigger-action" do
    assert_raise AssertionError, ~r/Found multiple forms with phx-trigger-action/, fn ->
      :phoenix
      |> session()
      |> visit("/live/trigger-action")
      |> click(~l"Trigger multiple"e)
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
