defmodule Cerberus.LiveTriggerActionBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias ExUnit.AssertionError

  @shared_browser_session_boot_timeout_ms 30_000
  @shared_browser_session_stop_timeout_ms 5_000

  setup_all do
    {owner_pid, browser_session} = start_shared_browser_session!()

    on_exit(fn ->
      stop_shared_browser_session(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "phx-trigger-action submits to static endpoint after phx-submit (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/trigger-action")
      |> fill_in("Trigger action", "engage")
      |> submit(text: "Submit Trigger Form")
      |> assert_path("/trigger-action/result")
      |> assert_has(text("method: POST", exact: true))
    end

    test "phx-trigger-action can be triggered from outside the form (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/trigger-action")
      |> click_button(text: "Trigger from elsewhere")
      |> assert_path("/trigger-action/result")
      |> assert_has(text("method: POST", exact: true))
    end

    test "phx-trigger-action is ignored when click event redirects or navigates (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/trigger-action")
      |> click_button(text: "Redirect and trigger action")
      |> assert_path("/live/counter")
      |> assert_has(text("Counter", exact: true))
      |> visit("/live/trigger-action")
      |> click_button(text: "Navigate and trigger action")
      |> assert_path("/live/counter")
      |> assert_has(text("Counter", exact: true))
    end

    test "dynamically rendered forms can trigger action submit (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
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

  defp driver_session(:phoenix, _context), do: session(:phoenix)
  defp driver_session(:browser, context), do: context.shared_browser_session

  defp start_shared_browser_session! do
    parent = self()

    owner_pid =
      spawn_link(fn ->
        try do
          browser_session = session(:browser)
          send(parent, {:shared_browser_session_ready, self(), browser_session})

          receive do
            :stop -> :ok
          end
        rescue
          error ->
            send(parent, {:shared_browser_session_failed, self(), error, __STACKTRACE__})
        end
      end)

    receive do
      {:shared_browser_session_ready, ^owner_pid, browser_session} ->
        {owner_pid, browser_session}

      {:shared_browser_session_failed, ^owner_pid, error, stacktrace} ->
        reraise(error, stacktrace)
    after
      @shared_browser_session_boot_timeout_ms ->
        Process.exit(owner_pid, :kill)

        raise "timed out starting shared browser session after #{@shared_browser_session_boot_timeout_ms}ms"
    end
  end

  defp stop_shared_browser_session(owner_pid) when is_pid(owner_pid) do
    if Process.alive?(owner_pid) do
      ref = Process.monitor(owner_pid)
      send(owner_pid, :stop)

      receive do
        {:DOWN, ^ref, :process, ^owner_pid, _reason} -> :ok
      after
        @shared_browser_session_stop_timeout_ms ->
          Process.exit(owner_pid, :kill)
      end
    end

    :ok
  end
end
