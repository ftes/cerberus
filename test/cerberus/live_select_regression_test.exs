defmodule Cerberus.LiveSelectRegressionTest do
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
    test "multi-select preserves previous picks across repeated calls (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> select(~l"Race 2"l, option: text("Elf"))
      |> select(~l"Race 2"l, option: text("Dwarf"))
      |> click(role(:button, name: "Save Full Form"))
      |> assert_has(and_(css("#form-data"), text("[elf, dwarf]", exact: false)))
    end

    test "select outside forms dispatches option phx-click events (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> within(css("#not-a-form"), fn scoped ->
        select(scoped, ~l"Choose a pet:"l, option: [text("Dog"), text("Cat")])
      end)
      |> assert_has(and_(css("#form-data"), text("selected: [dog, cat]")))
    end

    test "select outside forms without option phx-click raises a contract error (#{driver})", context do
      test_session =
        unquote(driver)
        |> driver_session(context)
        |> visit("/phoenix_test/live/index")

      assert_contract_error(fn ->
        select(test_session, css("#no-form-no-phx-click-select"), option: text("Dog"), timeout: 10)
      end)
    end

    test "link click raises ambiguity error when duplicate text matches (#{driver})", context do
      error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> driver_session(context)
          |> visit("/phoenix_test/live/index")
          |> click(role(:link, name: "Multiple links", exact: false))
        end

      assert error.message =~ "2 elements matched locator"
    end

    test "button click raises ambiguity error when duplicate text matches (#{driver})", context do
      error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> driver_session(context)
          |> visit("/phoenix_test/live/index")
          |> click(role(:button, name: "Duplicate button with wrapped id", exact: true))
        end

      assert error.message =~ "2 elements matched locator"
    end

    test "field actions raise ambiguity error when duplicate labels match (#{driver})", context do
      error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> driver_session(context)
          |> visit("/phoenix_test/live/index")
          |> fill_in(css("input[id$='characters']"), "Bilbo")
        end

      assert error.message =~ "2 elements matched locator"
    end

    test "explicit position disambiguates duplicate link and button actions (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/live/index")
      |> click(role(:link, name: "Multiple links", exact: false), nth: 2)
      |> assert_path("/phoenix_test/live/page_4")

      unquote(driver)
      |> driver_session(context)
      |> visit("/live/selector-edge")
      |> click(role(:button, name: "Apply"), first: true)
      |> assert_has(text("Selected: primary", exact: true))

      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> fill_in(role(:textbox, name: ~r/^Search term/), "gondor", last: true)
      |> submit(role(:button, name: ~r/^Run/), last: true)
      |> assert_path("/search/nested/results", query: [nested_q: "gondor"])
    end
  end

  defp driver_session(:phoenix, %{conn: conn}), do: session(conn)
  defp driver_session(:browser, context), do: SharedBrowserSession.driver_session(:browser, context)

  defp assert_contract_error(fun) when is_function(fun, 0) do
    assert_raise_regex(
      [ArgumentError, ExUnit.AssertionError],
      ~r/valid `phx-click` attribute.*belong to a `form`|expected select options to have a valid `phx-click` attribute or belong to a `form`/,
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
