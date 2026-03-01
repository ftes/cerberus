defmodule CerberusTest.SelectChooseBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:phoenix, :browser] do
    test "select submits a chosen option across static and browser drivers (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/controls")
      |> select("Race", option: "Dwarf")
      |> submit(text("Save Controls"))
      |> assert_has(text("race: dwarf", exact: true))
    end

    test "select/choose/submit support testid locators on static routes (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/controls")
      |> select(testid("controls-race-select"), option: "Dwarf")
      |> choose(testid("controls-contact-email"))
      |> submit(testid("save-controls"))
      |> assert_has(text("race: dwarf", exact: true))
      |> assert_has(text("contact: email", exact: true))
    end

    test "select preserves prior multi-select values across repeated calls (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/controls")
      |> select("Race 2", option: "Elf")
      |> select("Race 2", option: "Dwarf")
      |> submit(text("Save Controls"))
      |> assert_has(text("race_2: [elf,dwarf]", exact: true))
    end

    test "submit keeps default select and radio values when untouched (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/controls")
      |> submit(text("Save Controls"))
      |> assert_has(text("race: human", exact: true))
      |> assert_has(text("contact: mail", exact: true))
    end

    test "choose sets the selected radio value across static and browser drivers (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/controls")
      |> choose("Email Choice")
      |> submit(text("Save Controls"))
      |> assert_has(text("contact: email", exact: true))
    end

    test "select rejects disabled options (#{driver})" do
      assert_raise ExUnit.AssertionError, ~r/disabled/, fn ->
        unquote(driver)
        |> session()
        |> visit("/controls")
        |> select("Race", option: "Disabled Race")
      end
    end

    test "select on LiveView triggers change payload updates (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/controls")
      |> select("Race", option: "Elf")
      |> assert_has(text("_target: [race]", exact: true))
      |> assert_has(text("race: elf", exact: true))
    end

    test "select supports testid locators on live routes (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/controls")
      |> select(testid("live-race-select"), option: "Elf")
      |> assert_has(text("_target: [race]", exact: true))
      |> assert_has(text("race: elf", exact: true))
    end

    test "choose supports testid locators on live routes (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/controls")
      |> choose(testid("live-contact-phone"))
      |> assert_has(text("contact: phone", exact: true))
    end

    test "submit supports testid locator on live routes (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/controls")
      |> submit(testid("save-live-controls"))
      |> assert_has(text("race: human", exact: true))
      |> assert_has(text("contact: mail", exact: true))
    end

    test "choose on LiveView updates the selected radio (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/controls")
      |> choose("Phone Choice")
      |> assert_has(text("contact: phone", exact: true))
    end

    test "LiveView select preserves multi-select values across repeated calls (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/controls")
      |> select("Race 2", option: "Elf")
      |> assert_has(text("race_2: [elf]", exact: true))
      |> select("Race 2", option: "Dwarf")
      |> assert_has(text("race_2: [elf,dwarf]", exact: true))
    end

    test "LiveView submit keeps default select and radio values when untouched (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/controls")
      |> submit(text("Save Live Controls"))
      |> assert_has(text("race: human", exact: true))
      |> assert_has(text("contact: mail", exact: true))
    end
  end
end
