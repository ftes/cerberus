defmodule Cerberus.ValueAssertionsTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Cerberus.Browser, only: [evaluate_js: 2]

  alias Cerberus.TestSupport.SharedBrowserSession

  setup_all do
    {owner_pid, browser_session} = SharedBrowserSession.start!()

    on_exit(fn ->
      SharedBrowserSession.stop(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "assert_value/refute_value check current form-field values (#{driver})", context do
      unquote(driver)
      |> SharedBrowserSession.driver_session(context)
      |> visit("/search")
      |> assert_value(~l"Search term"l, "")
      |> fill_in(~l"Search term"l, "gandalf")
      |> assert_value(~l"Search term"l, "gandalf")
      |> assert_value(~l"Search term"l, ~r/gandal/)
      |> refute_value(~l"Search term"l, "aragorn")
      |> refute_value(~l"Search term"l, ~r/aragorn/)
    end

    test "value assertions fail with clear reasons when fields are missing (#{driver})", context do
      assert_raise ExUnit.AssertionError, ~r/assert_value failed: no form field matched locator/, fn ->
        unquote(driver)
        |> SharedBrowserSession.driver_session(context)
        |> visit("/search")
        |> assert_value(~l"Missing field"l, "value", timeout: 50)
      end

      assert_raise ExUnit.AssertionError, ~r/refute_value failed: no form field matched locator/, fn ->
        unquote(driver)
        |> SharedBrowserSession.driver_session(context)
        |> visit("/search")
        |> refute_value(~l"Missing field"l, "value", timeout: 50)
      end
    end
  end

  test "browser assert_value retries until the JS value matches", %{shared_browser_session: browser_session} do
    browser_session
    |> visit("/search")
    |> evaluate_js("""
    setTimeout(() => {
      const input = document.getElementById("search_q");
      if (input) input.value = "late-value";
    }, 120);
    """)
    |> assert_value(~l"Search term"l, "late-value", timeout: 500)
  end
end
