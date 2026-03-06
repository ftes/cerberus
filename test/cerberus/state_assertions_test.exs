defmodule Cerberus.StateAssertionsTest do
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
    test "checked assertion helpers support state filtering and count constraints (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/page/index")
      |> assert_checked(~l"Mail Choice"l)
      |> refute_checked(~l"Email Choice"l)
      |> assert_checked(css("input[name='contact']"), count: 1)
      |> refute_checked(css("input[name='contact']"), min: 2)
    end

    test "selected assertion helpers work for selected and unselected controls (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/page/index")
      |> assert_selected(~l"Mail Choice"l)
      |> refute_selected(~l"Phone Choice"l)
    end

    test "disabled assertion helpers work for disabled and enabled fields (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/page/index")
      |> assert_disabled(~l"Disabled textaread"l)
      |> refute_disabled(~l"Notes"l)
    end

    test "readonly assertion helpers work for readonly and editable fields (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/phoenix_test/page/index")
      |> assert_readonly(~l"Readonly notes"l)
      |> refute_readonly(~l"Notes"l)
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
