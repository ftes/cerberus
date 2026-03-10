defmodule Cerberus.LiveCheckboxBehaviorTest do
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

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  for driver <- [:phoenix, :browser] do
    test "outside-form checkbox with phx-click toggles state (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> within(css("#not-a-form"), fn scoped ->
        scoped
        |> check(~l"Second Breakfast"l)
        |> uncheck(~l"Second Breakfast"l)
      end)
      |> refute_has(and_(css("#form-data"), text("value: second-breakfast")))
    end

    test "label-based nameless checkbox phx-click toggles the checked payload (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> assert_has(and_(css("#checkbox-phx-click-values-abc-value"), text("Unchecked")))
      |> check(~l"Checkbox abc"l, timeout: 50)
      |> assert_has(and_(css("#checkbox-phx-click-values-abc-value"), text("Checked")))
    end

    test "label-based nameless checkbox phx-click sends browser-default on value (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> assert_has(and_(css("#checkbox-phx-click-default-on-value"), text("unset")))
      |> check(~l"Checkbox default on"l, timeout: 50)
      |> assert_has(and_(css("#checkbox-phx-click-default-on-value"), text("on")))
    end

    test "css-located nameless checkbox phx-click sends browser-default on value (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> assert_has(and_(css("#checkbox-phx-click-default-on-value"), text("unset")))
      |> check(css("#checkbox-phx-click-default-on"), timeout: 50)
      |> assert_has(and_(css("#checkbox-phx-click-default-on-value"), text("on")))
    end

    test "outside-form checkbox without phx-click raises contract error (#{driver})", context do
      test_session =
        unquote(driver)
        |> driver_session(context)
        |> visit("/phoenix_test/live/index")

      assert_contract_error(fn ->
        check(test_session, css("#no-form-no-phx-click-checkbox"), timeout: 10)
      end)
    end
  end

  defp driver_session(:phoenix, %{conn: conn}), do: session(conn)
  defp driver_session(:browser, context), do: SharedBrowserSession.driver_session(:browser, context)

  defp assert_contract_error(fun) when is_function(fun, 0) do
    assert_raise_regex(
      [ArgumentError, ExUnit.AssertionError],
      ~r/have a valid `phx-click` attribute or belong to a `form`/,
      fun
    )
  end

  defp assert_raise_regex([exception | rest], regex, fun) do
    assert_raise exception, regex, fun
  rescue
    ExUnit.AssertionError ->
      case rest do
        [] -> reraise ExUnit.AssertionError, __STACKTRACE__
        _ -> assert_raise_regex(rest, regex, fun)
      end
  end
end
