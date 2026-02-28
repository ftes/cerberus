defmodule Cerberus.CoreCheckboxArrayBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @tag drivers: [:live, :browser]
  test "check supports array-named checkbox groups", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/checkbox-array")
      |> check("Two")
      |> assert_has(text("Selected Items: one,two", exact: true))
    end)
  end

  @tag drivers: [:live, :browser]
  test "uncheck supports array-named checkbox groups", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/checkbox-array")
      |> uncheck("One")
      |> assert_has(text("Selected Items: None", exact: true))
    end)
  end

  @tag drivers: [:static, :browser]
  test "static submit payload matches browser for checked array values", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/checkbox-array")
      |> check("Two")
      |> submit(text("Save Items"))
      |> assert_has(text("Selected Items: one,two", exact: true))
    end)
  end

  @tag drivers: [:static, :browser]
  test "static submit payload matches browser for unchecked array values", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/checkbox-array")
      |> uncheck("One")
      |> submit(text("Save Items"))
      |> assert_has(text("Selected Items: None", exact: true))
    end)
  end
end
