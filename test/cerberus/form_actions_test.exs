defmodule Cerberus.FormActionsTest do
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
    test "click_link, fill_in, and submit are consistent across static and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> click(~l"Articles"e)
      |> assert_has(~l"Articles"e)
      |> visit("/search")
      |> fill_in(~l"Search term"l, "phoenix")
      |> submit(~l"Run Search"e)
      |> assert_has(~l"Search query: phoenix"e)
    end

    test "submit/1 submits the active form (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> fill_in(~l"Search term *"l, "compat")
      |> submit()
      |> assert_has(~l"Nested search query: compat"e)
    end

    test "submit/1 fails when no active form exists (#{driver})", context do
      assert_raise ExUnit.AssertionError, ~r/requires an active form/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/search")
        |> submit()
      end
    end

    test "fill_in matches wrapped labels with nested inline text across static and browser drivers (#{driver})",
         context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> fill_in(~l"Search term *"l, "phoenix")
      |> submit(~l"Run Nested Search"e)
      |> assert_has(~l"Nested search query: phoenix"e)
    end

    test "submit normalizes nested form params for non-GET requests (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/nested-submit")
      |> fill_in(~l"Email"l, "someone-1@teamengine.co.uk")
      |> fill_in(~l"Password"l, "Pass123456789!")
      |> submit(~l"Sign In"e)
      |> assert_has(~l"session.email: someone-1@teamengine.co.uk"e)
      |> assert_has(~l"session.password: Pass123456789!"e)
      |> assert_has(~l"flat session[email] key?: false"e)
      |> assert_has(~l"flat session[password] key?: false"e)
    end

    test "click_button works on live counter flow for live and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/counter")
      |> click(~l"Increment"e)
      |> assert_has(~l"Count: 1"e)
    end

    if driver == :browser do
      @tag :slow
    end

    test "action failures include possible candidate hints (#{driver})", context do
      click_error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> driver_session(context)
          |> visit("/search")
          |> click(~l"Definitely Missing Link"e, timeout: 50)
        end

      assert click_error.message =~ "possible candidates:"
      assert click_error.message =~ "Articles"

      fill_error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> driver_session(context)
          |> visit("/search")
          |> fill_in(~l"Definitely Missing Field"l, "x")
        end

      assert fill_error.message =~ "possible candidates:"
      assert fill_error.message =~ "Search term"

      submit_error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> driver_session(context)
          |> visit("/search")
          |> submit(~l"Definitely Missing Submit"e)
        end

      assert submit_error.message =~ "possible candidates:"
      assert submit_error.message =~ "Run Search"
    end

    test "role locator failures include possible candidate hints (#{driver})", context do
      role_click_error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> driver_session(context)
          |> visit("/search")
          |> click(role(:link, name: "Definitely Missing Link"))
        end

      assert role_click_error.message =~ "possible candidates:"
      assert role_click_error.message =~ "Articles"
    end
  end

  test "submit/1 can submit active live forms without a submit button when phx-submit is defined (phoenix)" do
    :phoenix
    |> session()
    |> visit("/live/form-change")
    |> fill_in(~l"No button name"l, "Arnor")
    |> submit()
    |> assert_has(text("No button submit: Arnor", exact: true))
  end

  test "submit/1 errors when active live form has neither phx-submit nor action (phoenix)" do
    assert_raise ExUnit.AssertionError, ~r/`phx-submit` or `action` defined/, fn ->
      :phoenix
      |> session()
      |> visit("/live/form-change")
      |> fill_in(~l"Name (no phx-change)"l, "Arnor")
      |> submit()
    end
  end

  test "submit/1 keeps active live form values when conditional fields are removed (phoenix)" do
    :phoenix
    |> session()
    |> visit("/phoenix_test/live/index")
    |> fill_in(css("input[name='to_keep']"), "this input should stay")
    |> fill_in(css("input[name='to_remove']"), "this input will now be removed")
    |> submit()
    |> check(css("input[name='hide_to_remove']"))
    |> submit()
    |> assert_has(and_(css("#form-data"), text("this input should stay", exact: false)))
    |> refute_has(and_(css("#form-data"), text("this input will now be removed", exact: false)))
  end

  @tag skip: "browser submit-active-form-no-button parity bug"
  test "submit/1 parity for no-button live forms in browser driver" do
    :browser
    |> session()
    |> visit("/live/form-change")
    |> fill_in(~l"No button name"l, "Arnor")
    |> submit()
    |> assert_has(text("No button submit: Arnor", exact: true))
  end

  test "live driver reports missing fields for fill_in and missing submit controls on counter page" do
    assert_raise ExUnit.AssertionError, ~r/no form field matched locator/, fn ->
      :phoenix
      |> session()
      |> visit("/live/counter")
      |> fill_in(~l"Search term"l, "x")
    end

    assert_raise ExUnit.AssertionError, ~r/no submit button matched locator/, fn ->
      :phoenix
      |> session()
      |> visit("/live/counter")
      |> submit(~l"Run Search"e)
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
