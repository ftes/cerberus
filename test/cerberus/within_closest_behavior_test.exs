defmodule Cerberus.WithinClosestBehaviorTest do
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
    test "scoped assert_has/refute_has support closest with nested has filters (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/field-wrapper-errors")
      |> assert_has(filter(closest(css(".fieldset"), from: ~l"Email"l), has: text("can't be blank", exact: false)))
      |> assert_has(filter(closest(css(".fieldset"), from: ~l"Email"l), has_not: text("Outer wrapper error")))
    end

    test "scoped click supports closest scope locator (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/scoped")
      |> within(
        closest(css("section"), from: text("Secondary Panel", exact: true)),
        &click(&1, role(:link, name: "Open"))
      )
      |> assert_path("/search")
    end

    test "within supports has label filters for Phoenix-style field wrappers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/field-wrapper-errors")
      |> within(".fieldset" |> css() |> filter(has: ~l"Name"le), fn scoped ->
        scoped
        |> assert_has(text("Name can't be blank", exact: true))
        |> refute_has(text("Email can't be blank", exact: true))
      end)
    end

    test "within closest picks only nearest nested field wrapper from label locator (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/field-wrapper-errors")
      |> within(
        closest(css(".fieldset"), from: ~l"Email"le),
        &(&1
          |> assert_has(text("Email can't be blank", exact: true))
          |> refute_has(text("Outer wrapper error", exact: true)))
      )
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
