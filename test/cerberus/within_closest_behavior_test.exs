defmodule Cerberus.WithinClosestBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:phoenix, :browser] do
    test "within supports has label filters for Phoenix-style field wrappers (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/field-wrapper-errors")
      |> within(css(".fieldset", has: label("Name", exact: true)), fn scoped ->
        scoped
        |> assert_has(text("Name can't be blank", exact: true))
        |> refute_has(text("Email can't be blank", exact: true))
      end)
    end

    test "within closest picks only nearest nested field wrapper from label locator (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/field-wrapper-errors")
      |> within(closest(css(".fieldset"), from: label("Email", exact: true)), fn scoped ->
        scoped
        |> assert_has(text("Email can't be blank", exact: true))
        |> refute_has(text("Outer wrapper error", exact: true))
      end)
    end
  end
end
