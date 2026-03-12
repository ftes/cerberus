defmodule Cerberus.SelectChooseBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.TestSupport.SharedBrowserSession

  setup_all do
    {owner_pid, browser_session} = SharedBrowserSession.start!(SharedBrowserSession.maybe_use_cdp_evaluate())

    on_exit(fn ->
      SharedBrowserSession.stop(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "select submits a chosen option across static and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/controls")
      |> select(~l"Race"l, ~l"Dwarf"e)
      |> submit(text("Save Controls"))
      |> assert_has(text("race: dwarf", exact: true))
    end

    test "expanded role helpers listbox/spinbutton work on static controls (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/controls")
      |> fill_in(role(:spinbutton, name: "Age"), "41")
      |> select(role(:listbox, name: "Race 2"), ~l"Orc"e)
      |> submit(text("Save Controls"))
      |> assert_has(text("age: 41", exact: true))
      |> assert_has(text("race_2: [orc]", exact: true))
    end

    test "select/choose/submit support testid locators on static routes (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/controls")
      |> select(testid("controls-race-select"), ~l"Dwarf"e)
      |> choose(testid("controls-contact-email"))
      |> submit(testid("save-controls"))
      |> assert_has(text("race: dwarf", exact: true))
      |> assert_has(text("contact: email", exact: true))
    end

    test "select replaces multi-select values across repeated calls (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/controls")
      |> select(~l"Race 2"l, ~l"Elf"e)
      |> select(~l"Race 2"l, ~l"Dwarf"e)
      |> submit(text("Save Controls"))
      |> assert_has(text("race_2: [dwarf]", exact: true))
    end

    test "select accepts full multi-select values list (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/controls")
      |> select(~l"Race 2"l, [~l"Elf"e, ~l"Dwarf"e])
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
      |> choose(~l"Email Choice"l)
      |> submit(text("Save Controls"))
      |> assert_has(text("contact: email", exact: true))
    end

    test "select rejects disabled options (#{driver})", context do
      assert_raise ExUnit.AssertionError, ~r/disabled/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/controls")
        |> select(~l"Race"l, ~l"Disabled Race"e)
      end
    end

    test "select on LiveView triggers change payload updates (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> select(~l"Race"l, ~l"Elf"e)
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
      |> select(role(:listbox, name: "Race 2"), ~l"Dwarf"e)
      |> assert_has(text("_target: [race_2]", exact: true))
      |> assert_has(text("race_2: [dwarf]", exact: true))
    end

    test "select supports testid locators on live routes (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> select(testid("live-race-select"), ~l"Elf"e)
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
      |> choose(~l"Phone Choice"l)
      |> assert_has(text("contact: phone", exact: true))
    end

    test "LiveView choose outside forms dispatches input phx-click payloads (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> within(css("#not-a-form"), fn scoped ->
        choose(scoped, ~l"Huey"l)
      end)
      |> assert_has(text("value: huey", exact: true))
    end

    test "LiveView select accumulates multi-select values across repeated calls (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> select(~l"Race 2"l, ~l"Elf"e)
      |> assert_has(text("race_2: [elf]", exact: true))
      |> select(~l"Race 2"l, ~l"Dwarf"e)
      |> assert_has(text("race_2: [elf,dwarf]", exact: true))
    end

    test "LiveView select accepts full multi-select values list (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> select(~l"Race 2"l, [~l"Elf"e, ~l"Dwarf"e])
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

  test "LiveView choose outside forms without phx-click raises a contract error" do
    live_session =
      :phoenix
      |> session()
      |> visit("/phoenix_test/live/index")

    assert_raise ArgumentError,
                 ~r/have a valid `phx-click` attribute or belong to a `form` element/,
                 fn ->
                   choose(live_session, css("#no-form-no-phx-click"), timeout: 10)
                 end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
