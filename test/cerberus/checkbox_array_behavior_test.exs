defmodule Cerberus.CheckboxArrayBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.TestSupport.SharedBrowserSession

  setup_all do
    {owner_pid, browser_session} = SharedBrowserSession.start!()

    on_exit(fn ->
      SharedBrowserSession.stop(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "check supports array-named checkbox groups (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/checkbox-array")
      |> check("Two")
      |> assert_has(text("Selected Items: one,two", exact: true))
    end

    test "check/uncheck support testid locators on live checkbox groups (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/checkbox-array")
      |> check(testid("live-item-two-checkbox"))
      |> uncheck(testid("live-item-one-checkbox"))
      |> assert_has(text("Selected Items: two", exact: true))
    end

    test "uncheck supports array-named checkbox groups (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/checkbox-array")
      |> uncheck("One")
      |> assert_has(text("Selected Items: None", exact: true))
    end

    test "static submit payload matches browser for checked array values (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/checkbox-array")
      |> check("Two")
      |> submit(text("Save Items"))
      |> assert_has(text("Selected Items: one,two", exact: true))
    end

    test "check/uncheck/submit support testid locators on static checkbox groups (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/checkbox-array")
      |> check(testid("item-two-checkbox"))
      |> uncheck(testid("item-one-checkbox"))
      |> submit(testid("save-items-submit"))
      |> assert_has(text("Selected Items: two", exact: true))
    end

    test "static submit payload matches browser for unchecked array values (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/checkbox-array")
      |> uncheck("One")
      |> submit(text("Save Items"))
      |> assert_has(text("Selected Items: None", exact: true))
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
