defmodule Cerberus.SelectChooseBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

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
    test "select submits a chosen option across static and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/controls")
      |> select(label("Race"), option: ~l"Dwarf"e)
      |> submit(text("Save Controls"))
      |> assert_has(text("race: dwarf", exact: true))
    end

    test "expanded role helpers listbox/spinbutton work on static controls (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/controls")
      |> fill_in(role(:spinbutton, name: "Age"), "41")
      |> select(role(:listbox, name: "Race 2"), option: ~l"Orc"e)
      |> submit(text("Save Controls"))
      |> assert_has(text("age: 41", exact: true))
      |> assert_has(text("race_2: [orc]", exact: true))
    end

    test "select/choose/submit support testid locators on static routes (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/controls")
      |> select(testid("controls-race-select"), option: ~l"Dwarf"e)
      |> choose(testid("controls-contact-email"))
      |> submit(testid("save-controls"))
      |> assert_has(text("race: dwarf", exact: true))
      |> assert_has(text("contact: email", exact: true))
    end

    test "select replaces multi-select values across repeated calls (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/controls")
      |> select(label("Race 2"), option: ~l"Elf"e)
      |> select(label("Race 2"), option: ~l"Dwarf"e)
      |> submit(text("Save Controls"))
      |> assert_has(text("race_2: [dwarf]", exact: true))
    end

    test "select accepts full multi-select values list (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/controls")
      |> select(label("Race 2"), option: [~l"Elf"e, ~l"Dwarf"e])
      |> submit(text("Save Controls"))
      |> assert_has(text("race_2: [elf,dwarf]", exact: true))
    end

    test "submit keeps default select and radio values when untouched (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/controls")
      |> submit(text("Save Controls"))
      |> assert_has(text("race: human", exact: true))
      |> assert_has(text("contact: mail", exact: true))
    end

    test "choose sets the selected radio value across static and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/controls")
      |> choose(label("Email Choice"))
      |> submit(text("Save Controls"))
      |> assert_has(text("contact: email", exact: true))
    end

    test "select rejects disabled options (#{driver})", context do
      assert_raise ExUnit.AssertionError, ~r/disabled/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/controls")
        |> select(label("Race"), option: ~l"Disabled Race"e)
      end
    end

    test "select on LiveView triggers change payload updates (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> select(label("Race"), option: ~l"Elf"e)
      |> assert_has(text("_target: [race]", exact: true))
      |> assert_has(text("race: elf", exact: true))
    end

    test "expanded role helpers listbox/spinbutton work on live controls (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> fill_in(role(:spinbutton, name: "Age"), "44")
      |> assert_has(text("_target: [age]", exact: true))
      |> assert_has(text("age: 44", exact: true))
      |> select(role(:listbox, name: "Race 2"), option: ~l"Dwarf"e)
      |> assert_has(text("_target: [race_2]", exact: true))
      |> assert_has(text("race_2: [dwarf]", exact: true))
    end

    test "select supports testid locators on live routes (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> select(testid("live-race-select"), option: ~l"Elf"e)
      |> assert_has(text("_target: [race]", exact: true))
      |> assert_has(text("race: elf", exact: true))
    end

    test "choose supports testid locators on live routes (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> choose(testid("live-contact-phone"))
      |> assert_has(text("contact: phone", exact: true))
    end

    test "submit supports testid locator on live routes (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> submit(testid("save-live-controls"))
      |> assert_has(text("race: human", exact: true))
      |> assert_has(text("contact: mail", exact: true))
    end

    test "choose on LiveView updates the selected radio (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> choose(label("Phone Choice"))
      |> assert_has(text("contact: phone", exact: true))
    end

    test "LiveView select accumulates multi-select values across repeated calls (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> select(label("Race 2"), option: ~l"Elf"e)
      |> assert_has(text("race_2: [elf]", exact: true))
      |> select(label("Race 2"), option: ~l"Dwarf"e)
      |> assert_has(text("race_2: [elf,dwarf]", exact: true))
    end

    test "LiveView select accepts full multi-select values list (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> select(label("Race 2"), option: [~l"Elf"e, ~l"Dwarf"e])
      |> assert_has(text("race_2: [elf,dwarf]", exact: true))
    end

    test "LiveView submit keeps default select and radio values when untouched (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> submit(text("Save Live Controls"))
      |> assert_has(text("race: human", exact: true))
      |> assert_has(text("contact: mail", exact: true))
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
