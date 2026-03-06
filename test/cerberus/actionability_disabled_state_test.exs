defmodule Cerberus.ActionabilityDisabledStateTest do
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
    test "disabled controls fail consistently on static routes (#{driver})", context do
      assert_raise ExUnit.AssertionError, ~r/matched field is disabled/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/controls")
        |> fill_in(~l"Disabled name"l, "blocked", timeout: 0)
      end

      assert_raise ExUnit.AssertionError, ~r/matched field is disabled/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/controls")
        |> check(~l"Disabled notify"l, timeout: 0)
      end

      assert_raise ExUnit.AssertionError, ~r/matched field is disabled/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/controls")
        |> choose(~l"Disabled contact"l, timeout: 0)
      end

      assert_raise ExUnit.AssertionError, ~r/matched field is disabled/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/controls")
        |> click(role(:button, name: "Disabled Action", exact: true), timeout: 0)
      end

      assert_raise ExUnit.AssertionError, ~r/matched field is disabled/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/controls")
        |> submit(role(:button, name: "Disabled Save Controls", exact: true), timeout: 0)
      end
    end

    test "disabled controls fail consistently on live routes (#{driver})", context do
      assert_raise ExUnit.AssertionError, ~r/matched field is disabled/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/live/controls")
        |> fill_in(~l"Disabled name"l, "blocked", timeout: 0)
      end

      assert_raise ExUnit.AssertionError, ~r/matched field is disabled/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/live/controls")
        |> check(~l"Disabled notify"l, timeout: 0)
      end

      assert_raise ExUnit.AssertionError, ~r/matched field is disabled/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/live/controls")
        |> choose(~l"Disabled contact"l, timeout: 0)
      end

      assert_raise ExUnit.AssertionError, ~r/matched select field is disabled/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/live/controls")
        |> select(~l"Disabled select"l, option: ~l"Cannot submit"e, timeout: 0)
      end

      assert_raise ExUnit.AssertionError, ~r/matched field is disabled/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/live/controls")
        |> click(role(:button, name: "Disabled Action", exact: true), timeout: 0)
      end

      assert_raise ExUnit.AssertionError, ~r/matched field is disabled/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/live/controls")
        |> submit(role(:button, name: "Disabled Save Live Controls", exact: true), timeout: 0)
      end
    end

    test "select waits for delayed enabled control on live routes (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/actionability/delayed")
      |> select(~l"Category"l, option: ~l"Advanced"e)
      |> select(~l"Role"l, option: ~l"Analyst"e, timeout: 600)
      |> assert_has(text("role: analyst", exact: true))
      |> assert_has(text("role_enabled: true", exact: true))
    end

    test "check waits for delayed enabled control on live routes (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/actionability/delayed")
      |> select(~l"Category"l, option: ~l"Advanced"e)
      |> check(~l"Notify team"l, timeout: 600)
      |> assert_has(text("notify: true", exact: true))
      |> assert_has(text("notify_enabled: true", exact: true))
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
