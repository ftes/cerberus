defmodule Cerberus.WithinClosestBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:phoenix, :browser] do
    test "scoped assert_has/refute_has support closest without within callback (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/field-wrapper-errors")
      |> assert_has(closest(css(".fieldset"), from: label("Email")), text("can't be blank"))
      |> refute_has(closest(css(".fieldset"), from: label("Email")), text("Outer wrapper error"))
    end

    test "scoped click supports closest scope locator (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/scoped")
      |> click(closest(css("section"), from: text("Secondary Panel", exact: true)), link("Open"))
      |> assert_path("/search")
    end

    test "within supports has label filters for Phoenix-style field wrappers (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/field-wrapper-errors")
      |> within(".fieldset" |> css() |> has(label("Name", exact: true)), fn scoped ->
        scoped
        |> assert_has(text("Name can't be blank", exact: true))
        |> refute_has(text("Email can't be blank", exact: true))
      end)
    end

    test "within closest picks only nearest nested field wrapper from label locator (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/field-wrapper-errors")
      |> within(
        closest(css(".fieldset"), from: label("Email", exact: true)),
        &(&1
          |> assert_has(text("Email can't be blank", exact: true))
          |> refute_has(text("Outer wrapper error", exact: true)))
      )
    end
  end
end
