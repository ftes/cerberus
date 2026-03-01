defmodule Cerberus.CoreSelectChooseBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @tag :static
  @tag :browser
  test "select submits a chosen option across static and browser drivers", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/controls")
      |> select("Race", option: "Dwarf")
      |> submit(text("Save Controls"))
      |> assert_has(text("race: dwarf", exact: true))
    end)
  end

  @tag :static
  @tag :browser
  test "select preserves prior multi-select values across repeated calls", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/controls")
      |> select("Race 2", option: "Elf")
      |> select("Race 2", option: "Dwarf")
      |> submit(text("Save Controls"))
      |> assert_has(text("race_2: [elf,dwarf]", exact: true))
    end)
  end

  @tag :static
  @tag :browser
  test "submit keeps default select and radio values when untouched", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/controls")
      |> submit(text("Save Controls"))
      |> assert_has(text("race: human", exact: true))
      |> assert_has(text("contact: mail", exact: true))
    end)
  end

  @tag :static
  @tag :browser
  test "choose sets the selected radio value across static and browser drivers", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/controls")
      |> choose("Email Choice")
      |> submit(text("Save Controls"))
      |> assert_has(text("contact: email", exact: true))
    end)
  end

  @tag :static
  @tag :browser
  test "select rejects disabled options", context do
    results =
      Harness.run(context, fn session ->
        session
        |> visit("/controls")
        |> select("Race", option: "Disabled Race")
      end)

    assert Enum.all?(results, &(&1.status == :error))
    assert Enum.all?(results, &String.contains?(&1.message || "", "disabled"))
  end

  @tag :live
  @tag :browser
  test "select on LiveView triggers change payload updates", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/controls")
      |> select("Race", option: "Elf")
      |> assert_has(text("_target: [race]", exact: true))
      |> assert_has(text("race: elf", exact: true))
    end)
  end

  @tag :live
  @tag :browser
  test "choose on LiveView updates the selected radio", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/controls")
      |> choose("Phone Choice")
      |> assert_has(text("contact: phone", exact: true))
    end)
  end

  @tag :live
  @tag :browser
  test "LiveView select preserves multi-select values across repeated calls", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/controls")
      |> select("Race 2", option: "Elf")
      |> assert_has(text("race_2: [elf]", exact: true))
      |> select("Race 2", option: "Dwarf")
      |> assert_has(text("race_2: [elf,dwarf]", exact: true))
    end)
  end

  @tag :live
  @tag :browser
  test "LiveView submit keeps default select and radio values when untouched", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/controls")
      |> submit(text("Save Live Controls"))
      |> assert_has(text("race: human", exact: true))
      |> assert_has(text("contact: mail", exact: true))
    end)
  end
end
