defmodule Cerberus.CoreLiveTriggerActionBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias ExUnit.AssertionError

  for driver <- [:phoenix, :browser] do
    test "phx-trigger-action submits to static endpoint after phx-submit (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/trigger-action")
      |> fill_in("Trigger action", "engage")
      |> submit(text: "Submit Trigger Form")
      |> assert_path("/trigger-action/result")
      |> assert_has(text("method: POST", exact: true))
    end

    test "phx-trigger-action can be triggered from outside the form (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/trigger-action")
      |> click_button(text: "Trigger from elsewhere")
      |> assert_path("/trigger-action/result")
      |> assert_has(text("method: POST", exact: true))
    end

    test "phx-trigger-action is ignored when click event redirects or navigates (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/trigger-action")
      |> click_button(text: "Redirect and trigger action")
      |> assert_path("/live/counter")
      |> assert_has(text("Counter", exact: true))
      |> visit("/live/trigger-action")
      |> click_button(text: "Navigate and trigger action")
      |> assert_path("/live/counter")
      |> assert_has(text("Counter", exact: true))
    end

    test "dynamically rendered forms can trigger action submit (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/trigger-action")
      |> click_button(text: "Show Dynamic Form")
      |> fill_in("Message", "dynamic")
      |> submit(text: "Submit Dynamic Form")
      |> assert_path("/trigger-action/result")
      |> assert_has(text("method: POST", exact: true))
    end
  end

  test "live driver keeps default hidden payload when triggered from outside form" do
    :phoenix
    |> session()
    |> visit("/live/trigger-action")
    |> click_button(text: "Trigger from elsewhere")
    |> assert_path("/trigger-action/result")
    |> assert_has(text("trigger_action_hidden_input: trigger_action_hidden_value", exact: true))
    |> refute_has(text("trigger_action_input: engage", exact: true))
  end

  test "live driver submits merged payload for trigger-action handoff" do
    :phoenix
    |> session()
    |> visit("/live/trigger-action")
    |> fill_in("Trigger action", "engage")
    |> submit(text: "Submit Trigger Form")
    |> assert_path("/trigger-action/result")
    |> assert_has(text("trigger_action_hidden_input: trigger_action_hidden_value", exact: true))
    |> assert_has(text("trigger_action_input: engage", exact: true))
  end

  test "phx-trigger-action runs after patch-producing phx-change" do
    :phoenix
    |> session()
    |> visit("/live/trigger-action")
    |> fill_in("Patch and trigger action", "let's go")
    |> assert_path("/trigger-action/result")
    |> assert_has(text("patch_and_trigger_action: let's go", exact: true))
  end

  test "live driver submits dynamic form payload on trigger-action handoff" do
    :phoenix
    |> session()
    |> visit("/live/trigger-action")
    |> click_button(text: "Show Dynamic Form")
    |> fill_in("Message", "dynamic")
    |> submit(text: "Submit Dynamic Form")
    |> assert_path("/trigger-action/result")
    |> assert_has(text("message: dynamic", exact: true))
  end

  test "raises an error if multiple forms have phx-trigger-action" do
    assert_raise AssertionError, ~r/Found multiple forms with phx-trigger-action/, fn ->
      :phoenix
      |> session()
      |> visit("/live/trigger-action")
      |> click_button(text: "Trigger multiple")
    end
  end
end
