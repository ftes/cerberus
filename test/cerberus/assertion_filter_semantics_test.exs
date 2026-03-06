defmodule Cerberus.AssertionFilterSemanticsTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.TestSupport.SharedBrowserSession

  @missing_label "Unknown Label"

  setup_all do
    {owner_pid, browser_session} = SharedBrowserSession.start!()

    on_exit(fn ->
      SharedBrowserSession.stop(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "refute_has supports label-only locators when label text is missing (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/form-change")
      |> refute_has(label(@missing_label, exact: true))
    end

    test "assert_has with label-only locator fails when label text is missing (#{driver})", context do
      assert_raise ExUnit.AssertionError, ~r/expected text not found/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/live/form-change")
        |> assert_has(label(@missing_label, exact: true), timeout: 0)
      end
    end

    test "assert_has rejects unknown option keys with explicit errors (#{driver})", context do
      assert_raise ArgumentError,
                   ~r/assert_has\/3 invalid options/,
                   fn ->
                     unquote(driver)
                     |> driver_session(context)
                     |> visit("/articles")
                     |> assert_has(text("Articles"), with: "Articles")
                   end
    end

    test "refute_has rejects unknown option keys with explicit errors (#{driver})", context do
      assert_raise ArgumentError,
                   ~r/refute_has\/3 invalid options/,
                   fn ->
                     unquote(driver)
                     |> driver_session(context)
                     |> visit("/articles")
                     |> refute_has(text("Articles"), with: "Articles")
                   end
    end

    test "assertions can match value attributes on static pages (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/controls")
      |> assert_has(css("input[value='33']"))
      |> assert_has(~l"Age"le)
      |> refute_has(css("input[value='99']"))
    end

    test "assertions can match updated value attributes on live pages (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> assert_has(css("input[value='33']"))
      |> assert_has(~l"Age"le)
      |> fill_in(~l"Age"l, "41")
      |> assert_has(css("input[value='41']"))
      |> refute_has(css("input[value='33']"))
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
